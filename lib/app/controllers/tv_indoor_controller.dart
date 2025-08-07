
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tv_indoor/app/controllers/config_controller.dart';
import 'package:tv_indoor/app/controllers/connectivity_controller.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';




class TvIndoorController extends GetxController {
  
  final RxList<Map<String, dynamic>> news = <Map<String,dynamic>>[].obs;
  final RxString loadingDots = ''.obs;
  final RxMap<String, dynamic> arquivoAtual = <String, dynamic>{}.obs;
  final RxString erroVideo = ''.obs;
  final RxString deviceId = ''.obs;
  final RxList<RxMap<String, dynamic>> midias = <RxMap<String, dynamic>>[].obs;
  final RxInt currentIndex = 0.obs;
  final RxBool isLoading = false.obs;
  final RxMap<String, dynamic> mediaAtual = <String, dynamic>{}.obs;
  final RxBool existeMidia = false.obs;
  final RxBool isWebview = false.obs;
  final RxString currentWebviewUrl = ''.obs;
  final RxBool webviewLoaded = false.obs;

  Timer? _mediaTimer;
  Dio dio = Dio();

  RxBool _stopLoop = false.obs;
  Timer? _imageTimer; // usado para cancelar facilmente o “delay de imagem”
  VideoPlayerController? videoController;
  final RxBool videoReady = false.obs;


  late final WebViewController webview;
  
  @override
  Future<void> onInit() async {
    super.onInit();
    
    // Verificar se tem controller de conectividade e configurar listener
    try {
      final connectivityController = Get.find<ConnectivityController>();
      connectivityController.isConnected.listen((isConnected) {
        if (!isConnected) {
          print('📡 Conexão perdida - pausando operações que dependem de internet');
          // Aqui você pode adicionar lógica específica se necessário
        } else {
          print('📡 Conexão restabelecida');
        }
      });
    } catch (e) {
      print('ConnectivityController não encontrado: $e');
    }
    
    // Inicializar WebView com configurações completas
    webview = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..enableZoom(true)
      ..setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Opcionalmente, você pode capturar o progresso do carregamento
          },
          onPageStarted: (String url) {
            // Página começou a carregar
            webviewLoaded.value = false;
          },
          onPageFinished: (String url) {
            // Página terminou de carregar
            webviewLoaded.value = true;
          },
          onWebResourceError: (WebResourceError error) {
            // Tratar erros de carregamento
            print('🚨 WebView error: ${error.description}');
            print('🚨 Error type: ${error.errorType}');
            print('🚨 Failed URL: ${error.url}');
            
            // Definir como carregado para não travar, mas com aviso
            webviewLoaded.value = true;
          },
          onNavigationRequest: (NavigationRequest request) {
            // Permite todas as navegações
            return NavigationDecision.navigate;
          },
        ),
      );

    // Configurar cookies e storage
    await _configureWebViewSettings();
    
    // Carregar página em branco inicialmente para evitar páginas padrão
    await webview.loadHtmlString('<html><body style="background:black;"></body></html>');
    
    isLoading.value = true;
    _scheduleNextReload(); // agenda primeiro reload em 10 minutos
    _stopLoop.value = false;
    await getMidias();

    if (midias.isNotEmpty) {
       existeMidia.value = true;
       currentIndex.value = 0;
      _playMediaNoIndice(currentIndex.value);
    } else {
      existeMidia.value = false;
      isLoading.value = false;
    }

  }

  // Configurar WebView com suporte completo para cookies, localStorage, sessionStorage
  Future<void> _configureWebViewSettings() async {
    try {
      print('🔧 Iniciando configuração do WebView...');
      
      // Configuração básica de cookies (apenas se disponível)
      if (Platform.isAndroid) {
        try {
          final cookieManager = WebViewCookieManager();
          await cookieManager.clearCookies();
          print('✅ Cookies limpos com sucesso');
        } catch (e) {
          print('⚠️ Erro ao configurar cookies: $e');
        }
      }

      // Injetar JavaScript básico para configurar storage
      try {
        await webview.runJavaScript('''
          console.log("🚀 Inicializando WebView...");
          
          // Testar localStorage básico
          try {
            if (typeof(Storage) !== "undefined") {
              localStorage.setItem('test', 'ok');
              console.log("✅ LocalStorage funcionando");
            }
          } catch(e) {
            console.log("⚠️ LocalStorage não disponível:", e);
          }
          
          // Configurar cookies básicos
          try {
            document.cookie = "webview=active; Path=/";
            console.log("✅ Cookies configurados");
          } catch(e) {
            console.log("⚠️ Erro ao configurar cookies:", e);
          }
          
          console.log("✅ WebView configurado");
        ''');
        print('✅ JavaScript executado com sucesso');
      } catch (e) {
        print('⚠️ Erro ao executar JavaScript: $e');
      }
      
    } catch (e) {
      print('❌ Erro ao configurar WebView: $e');
    }
  }

  Future<void> reload() async {
    print('🔄 =============== INICIANDO RELOAD ===============');
    isLoading.value = true;

    // Verificar conectividade antes de tentar atualizar
    try {
      final connectivityController = Get.find<ConnectivityController>();
      if (!connectivityController.isConnected.value) {
        _showToast('Sem conexão - pulando atualização');
        _scheduleNextReload();
        isLoading.value = false;
        return;
      }
    } catch (e) {
      print('Erro ao verificar conectividade: $e');
    }

    _showToast('Iniciando busca de mídias...');

    // ── 1. Buscar dados do servidor ─────────────────────────
    final cfg = Get.find<ConfigController>();
    try {
      await cfg.fetchData();  
      if (cfg.deviceData.isEmpty) {
        _showToast('Erro na busca - sem dados do servidor');
        _scheduleNextReload();
        isLoading.value = false;
        return;
      }
    } catch (e) {
      _showToast('Erro de conexão - cancelando busca');
      _scheduleNextReload();
      isLoading.value = false;
      return;
    }

    try {
      // ── 2. Verificar se as mídias mudaram ─────────────────────────
      final bool midiasMudaram = await cfg.verificarMidiasAlteradas();
      
      // Salvar outros dados (cotações, notícias, etc.)
      await cfg.saveCotacoes();
      await cfg.saveNoticias();
      await cfg.savePrevisaoTempo();
      await cfg.saveCotMetais();

      print('🔍 Mídias mudaram: $midiasMudaram');

      // ── 3A. NÃO mudou nada  →  simplesmente continua ────────────────────
      if (!midiasMudaram) {
        // Se um vídeo estava pausado, retomar
        if (videoController?.value.isInitialized == true &&
            !videoController!.value.isPlaying) {
          await videoController!.play();
        }
        _showToast('Busca concluída - sem alterações');
        _scheduleNextReload();
        isLoading.value = false;
        return;
      }

      // ── 3B. MUDOU → precisamos atualizar ────────────────────────────────
      print('🔄 Mídias alteradas - iniciando atualização...');
      
      // Parar o loop atual
      _stopLoop.value = true;
      _imageTimer?.cancel();
      _imageTimer = null;

      // Parar e limpar o vídeo atual
      if (videoController != null) {
        await videoController!.pause();
        await videoController!.dispose();
        videoController = null;
        videoReady.value = false;
      }

      // Limpar estado do WebView
      isWebview.value = false;
      webviewLoaded.value = false;
      await webview.loadHtmlString('<html><body style="background:black;"></body></html>');

      print('🔄 Estados limpos, iniciando download...');

      // ── 4. Baixar e gravar novas mídias ───────────────────
      await cfg.handleMidias(cfg.deviceData['midias']);

      print('✅ Download concluído, recarregando lista...');

      // ── 5. CRÍTICO: Aguardar um pouco para garantir que o arquivo foi gravado ───
      await Future.delayed(const Duration(milliseconds: 500));

      // ── 6. Recarregar lista do SharedPreferences ─────────────────────────
      await getMidias();
      
      print('📋 Mídias carregadas: ${midias.length}');
      midias.forEach((media) {
        print('  - ${media['tipo']}: ${media['url']}');
      });

      // ── 7. Reiniciar o sistema com as novas mídias ───────────────────────
      currentIndex.value = 0;
      _stopLoop.value = false;

      if (midias.isNotEmpty) {
        existeMidia.value = true;
        print('🎬 Iniciando reprodução da primeira mídia...');
        
        // AGUARDAR UM POUCO MAIS PARA GARANTIR QUE TUDO ESTÁ PRONTO
        await Future.delayed(const Duration(milliseconds: 1000));
        
        _playMediaNoIndice(0);
      } else {
        existeMidia.value = false;
        print('❌ Nenhuma mídia encontrada após atualização');
      }

      _showToast('Mídias atualizadas com sucesso');
      _scheduleNextReload();
      isLoading.value = false;

      print('✅ =============== RELOAD CONCLUÍDO ===============');

    } catch (e) {
      print('❌ Erro durante atualização: $e');
      _showToast('Erro durante atualização - $e');
      _scheduleNextReload();
      isLoading.value = false;
    }
  }


  Future<void> getMidias() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('midias');
    
    print('📂 JSON das mídias: $json');
    
    if (json == null) {
      midias.clear();
      print('📂 Nenhuma mídia salva encontrada');
      return;
    }
    
    try {
      final List<dynamic> rawMidias = jsonDecode(json) as List;
      print('📂 Mídias decodificadas: ${rawMidias.length}');
      
      midias.assignAll(
        rawMidias.map((e) {
          final Map<String, dynamic> midia = Map<String, dynamic>.from(e);
          midia['qlik_integration'] = midia['qlik_integration'] ?? false;
          midia['url_externa'] = midia['url_externa'];
          midia['url_original'] = midia['url_original'];
          return midia.obs;
        }).toList(),
      );
      
      print('📂 Mídias carregadas na variável: ${midias.length}');
      
      // Debug - mostrar cada mídia carregada
      for (int i = 0; i < midias.length; i++) {
        final media = midias[i];
        print('📂 Mídia $i: ${media['tipo']} - ${media['file'] ?? media['url']}');
      }
      
    } catch (e) {
      print('❌ Erro ao decodificar mídias: $e');
      midias.clear();
    }
  }

  Future<void> _playMediaNoIndice(int idx) async {
    if (_stopLoop.value) {
      print('🛑 Loop parado - não reproduzindo mídia');
      return;
    }

    if (midias.isEmpty) {
      print('❌ Lista de mídias vazia');
      existeMidia.value = false;
      isLoading.value = false;
      return;
    }

    print('🎬 Reproduzindo mídia no índice: $idx de ${midias.length}');

    // Limpar estado anterior para transições suaves
    isWebview.value = false;
    webviewLoaded.value = false;
    
    // Carregar página em branco para limpar WebView completamente
    await webview.loadHtmlString('<html><body style="background:black;"></body></html>');
    
    // Pequeno delay para limpar interface
    await Future.delayed(const Duration(milliseconds: 300));

    // Garantimos que o indice esteja dentro dos limites
    currentIndex.value = idx % midias.length;
    final m = midias[currentIndex.value];
    existeMidia.value = true;

    print('🎬 Tipo da mídia: ${m['tipo']}');
    print('🎬 URL/File: ${m['file'] ?? m['url']}');

    isLoading.value = true;
    videoReady.value = false;

    if (m['tipo'] == 'video' && m['file'] != null) {
      print('🎥 Reproduzindo vídeo: ${m['file']}');
      
      // → Tocar vídeo
      // ------------------------------------------------
      isWebview.value = false;
      if (videoController != null) {
        // Se já existia um controller anterior, descarte-o
        await videoController!.dispose();
        videoController = null;
      }

      videoController = VideoPlayerController.file(File(m['file'] as String))
        ..addListener(_onError);
      
      try {
        await videoController!.initialize();

        isLoading.value = false;
        videoReady.value = true;
        await videoController!.play();
        videoController!.setVolume(1);
        
        print('🎥 Vídeo iniciado - duração: ${videoController!.value.duration}');
        
        await Future.delayed(videoController!.value.duration);

        if (!_stopLoop.value) {
          final int proximo = (currentIndex.value + 1) % midias.length;
          print('🎥 Vídeo finalizado - próximo índice: $proximo');
          _playMediaNoIndice(proximo);
        }
      } catch (e) {
        print('❌ Erro ao reproduzir vídeo: $e');
        isLoading.value = false;
        if (!_stopLoop.value) {
          final int proximo = (currentIndex.value + 1) % midias.length;
          _playMediaNoIndice(proximo);
        }
      }

    } else if (m['tipo'] == 'imagem') {
      print('🖼️ Exibindo imagem: ${m['file']}');
      
      // → Mostrar imagem por 20 segundos
      isWebview.value = false;
      isLoading.value = false;
      
      await Future.delayed(const Duration(seconds: 20));
      
      if (!_stopLoop.value) {
        final int proximo = (currentIndex.value + 1) % midias.length;
        print('🖼️ Imagem finalizada - próximo índice: $proximo');
        _playMediaNoIndice(proximo);
      }

    } else if (m['tipo'] == 'url') {
      print('🌐 Carregando URL: ${m['url']}');
      
      // → Mostrar URL em WebView
      // Verificar conectividade antes de tentar carregar URL
      try {
        final connectivityController = Get.find<ConnectivityController>();
        if (!connectivityController.isConnected.value) {
          _showToast('Sem conexão - pulando mídia URL');
          isLoading.value = false;
          if (!_stopLoop.value) {
            final int proximo = (currentIndex.value + 1) % midias.length;
            _playMediaNoIndice(proximo);
          }
          return;
        }
      } catch (e) {
        print('Erro ao verificar conectividade para URL: $e');
      }

      // Primeiro limpar qualquer conteúdo anterior
      isWebview.value = false;
      
      // Carregar página em branco para limpar completamente
      await webview.loadHtmlString('<html><body style="background:black;"></body></html>');
      await Future.delayed(const Duration(milliseconds: 500)); // Aguardar limpeza
      
      isWebview.value = true;
      webviewLoaded.value = false;
      
      String? urlToLoad;
      
      if (m['qlik_integration'] == true) {
        // Buscar URL do Qlik com ticket
        final configController = Get.find<ConfigController>();
        urlToLoad = await configController.getQlikUrl(m['url']);
        
        if (urlToLoad == null) {
          _showToast('Erro ao obter URL Qlik - pulando mídia');
          if (!_stopLoop.value) {
            final int proximo = (currentIndex.value + 1) % midias.length;
            _playMediaNoIndice(proximo);
          }
          return;
        }
      } else {
        // URL externa direta
        urlToLoad = m['url_externa'] ?? m['url'];
      }
      
      if (urlToLoad != null) {
        currentWebviewUrl.value = urlToLoad;
        print('🌐 Carregando URL BI/Qlik: $urlToLoad');
        
        try {
          isLoading.value = true;
          
          // Carregamento DIRETO para BI - sem cache que interfere
          await webview.loadRequest(
            Uri.parse(urlToLoad),
            headers: {
              'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
              'Accept-Language': 'pt-BR,pt;q=0.9,en;q=0.8',
              'Accept-Encoding': 'gzip, deflate, br',
              'Cache-Control': 'no-cache, no-store, must-revalidate',
              'Pragma': 'no-cache',
              'Expires': '0',
              'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            },
          ).timeout(const Duration(seconds: 45));
          
          print('✅ URL carregada diretamente');
          
          // Aguardar mais tempo para BI carregar completamente
          await Future.delayed(const Duration(seconds: 5));
          
          // APENAS otimizações que NÃO quebram BI
          await webview.runJavaScript('''
            try {
              console.log('🔧 Configurando BI/Qlik...');
              
              // Configurar zoom otimizado de 90% para mostrar mais conteúdo na tela
              var viewport = document.querySelector('meta[name="viewport"]');
              var zoomValue = 0.9;
              var maxZoom = 3.0;
              var widthCompensation = '111%'; // 100/0.9 = 111%
              
              if (!viewport) {
                viewport = document.createElement('meta');
                viewport.name = 'viewport';
                viewport.content = 'width=device-width, initial-scale=' + zoomValue + ', maximum-scale=' + maxZoom + ', user-scalable=yes';
                document.head.appendChild(viewport);
              } else {
                // Atualizar viewport existente
                viewport.content = 'width=device-width, initial-scale=' + zoomValue + ', maximum-scale=' + maxZoom + ', user-scalable=yes';
              }
              
              // Aplicar zoom via CSS Transform otimizado para dashboards verticais
              document.body.style.transform = 'scale(' + zoomValue + ')';
              document.body.style.transformOrigin = '0 0';
              document.body.style.width = widthCompensation;
              
              // Otimizações para melhor uso do espaço vertical
              document.body.style.minHeight = '100vh';
              document.documentElement.style.height = '100%';
              document.body.style.margin = '0';
              document.body.style.padding = '0';
              
              // Remove APENAS elementos de publicidade específicos
              var adsSelectors = [
                'iframe[src*="doubleclick"]',
                'iframe[src*="googlesyndication"]', 
                'div[class*="advertisement"]',
                'div[id*="google_ads"]',
                '.ads',
                '[class*="ad-banner"]'
              ];
              
              adsSelectors.forEach(function(selector) {
                try {
                  var elements = document.querySelectorAll(selector);
                  elements.forEach(function(el) { 
                    el.style.display = 'none'; 
                  });
                } catch(e) { /* ignore */ }
              });
              
              // NÃO remove scripts (BI precisa)
              // NÃO desabilita pointer-events (BI precisa de interação)
              // NÃO remove event listeners (BI precisa de eventos)
              
              console.log('✅ BI/Qlik configurado sem quebrar funcionalidade');
            } catch(e) {
              console.log('⚠️ Erro na configuração (ignorado): ', e);
            }
          ''');
          
          webviewLoaded.value = true;
          isLoading.value = false;
          
        } catch (e) {
          print('❌ Erro ao carregar BI: $e');
          webviewLoaded.value = false;
          isLoading.value = false;
        }
        
        // Aguardar tempo de exibição (4 minutos) e passar para próxima mídia
        await Future.delayed(const Duration(minutes: 4));
        
        if (!_stopLoop.value) {
          final int proximo = (currentIndex.value + 1) % midias.length;
          print('🌐 WebView finalizado - próximo índice: $proximo');
          _playMediaNoIndice(proximo);
        }
      } else {
        // Se não conseguiu obter URL, pula para próxima mídia
        _showToast('URL inválida - pulando mídia');
        if (!_stopLoop.value) {
          final int proximo = (currentIndex.value + 1) % midias.length;
          print('❌ URL inválida - próximo índice: $proximo');
          _playMediaNoIndice(proximo);
        }
      }
    }
  }

  // Agenda próximo reload fixo em 10 minutos
  void _scheduleNextReload() {
    _mediaTimer?.cancel();
    _mediaTimer = Timer(const Duration(minutes: 10), () {
      reload();
    });
  }

  
  // Método simples para mostrar toast/snackbar
  void _showToast(String message) {
    try {
      Get.snackbar(
        '',
        message,
        titleText: const SizedBox.shrink(),
        backgroundColor: Colors.black54,
        colorText: Colors.white,
        margin: const EdgeInsets.all(20),
        borderRadius: 8,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
        isDismissible: true,
        forwardAnimationCurve: Curves.easeOutBack,
        reverseAnimationCurve: Curves.easeInBack,
      );
    } catch (e) {
      print('Toast: $message'); // Fallback para log
    }
  }

  void _onError() {
    if (videoController?.value.hasError ?? false) {
      erroVideo.value =
          'Erro ao reproduzir: ${videoController!.value.errorDescription}';
    }
  }

  @override
  void onClose() {
    _mediaTimer?.cancel();
    videoController?.dispose();
    super.onClose();
  }
}