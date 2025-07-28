
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

  // Configurações adicionais após o carregamento da página
  Future<void> _configurePageAfterLoad() async {
    try {
      // Aguardar um tempo adicional para garantir que todos os recursos carregaram
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Executar JavaScript para otimizar a página carregada
      await webview.runJavaScript('''
        // Aguardar o DOM estar completamente carregado
        if (document.readyState === 'loading') {
          document.addEventListener('DOMContentLoaded', function() {
            console.log('DOM completamente carregado');
          });
        }
        
        // Aguardar recursos externos (imagens, scripts, etc.)
        window.addEventListener('load', function() {
          console.log('Todos os recursos foram carregados');
        });
        
        // Forçar reflow para garantir renderização
        document.body.offsetHeight;
        
        // Configurar timeouts maiores para requests
        if (typeof jQuery !== 'undefined') {
          jQuery.ajaxSetup({ timeout: 30000 });
        }
        
        // Aguardar um pouco mais para frameworks como Qlik carregarem completamente
        setTimeout(function() {
          console.log('Página totalmente inicializada para BI');
        }, 2000);
      ''');
      
    } catch (e) {
      print('Erro ao configurar página após carregamento: \$e');
    }
  }

  Future<void> reload() async {
    isLoading.value = true;

    // Verificar conectividade antes de tentar atualizar
    try {
      final connectivityController = Get.find<ConnectivityController>();
      if (!connectivityController.isConnected.value) {
        _showToast('Sem conexão - pulando atualização');
        _scheduleNextReload(); // agenda próximo reload
        isLoading.value = false;
        return;
      }
    } catch (e) {
      print('Erro ao verificar conectividade: $e');
    }

    _showToast('Iniciando busca de mídias...');

    // ── 1. Checa rapidamente se há mídias novas ─────────────────────────
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
      final bool midiasMudaram = await cfg.verificarMidiasAlteradas();
      await cfg.saveCotacoes();
      await cfg.saveNoticias();
      await cfg.savePrevisaoTempo();
      await cfg.saveCotMetais();

      // ── 2A. NÃO mudou nada  →  simplesmente continua ────────────────────
      if (!midiasMudaram) {
        // Se, por acaso, um vídeo estava pausado, retomamos
        if (videoController?.value.isInitialized == true &&
            !videoController!.value.isPlaying) {
          await videoController!.play();
        }
        _showToast('Busca concluída - sem alterações');
        _scheduleNextReload();   // agenda próximo reload
        isLoading.value = false;
        return;                  // sai sem mexer em timers ou índices
      }

      // ── 2B. MUDOU → precisamos atualizar ────────────────────────────────
      _stopLoop.value = true;          // bloqueia callbacks de imagem/vídeo
      _imageTimer?.cancel();           // cancela timer de imagem, se houver
      _imageTimer = null;

      if (videoController != null) {
        await videoController!.pause();     // pausa o vídeo atual
        await videoController!.dispose();   // descarta controller + listeners
        videoController = null;
        videoReady.value = false;
      }

      // ── 3. Baixa e grava novas mídias (mostra o diálogo de progresso) ───
      await cfg.handleMidias(cfg.deviceData['midias']);   // aguarda download

      // ── 4. Recarrega lista salva no SharedPreferences ───────────────────
      await getMidias();
      currentIndex.value = 0;

      // ── 5. Libera o loop e começa do índice 0 ───────────────────────────
      _stopLoop.value = false;
      if (midias.isNotEmpty) {
        existeMidia.value = true;
        _playMediaNoIndice(0);
      } else {
        existeMidia.value = false;
        isLoading.value = false;
      }

      _showToast('Mídias atualizadas com sucesso');
      _scheduleNextReload();   // agenda próximo reload
      isLoading.value = false;

    } catch (e) {
      _showToast('Erro durante atualização - $e');
      _scheduleNextReload();
      isLoading.value = false;
    }
  }


  Future<void> getMidias() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('midias');
    if (json == null) {
      midias.clear();
      return;
    }
    
    // Carrega mídias com novos campos para URLs
    final List<dynamic> rawMidias = jsonDecode(json) as List;
    midias.assignAll(
      rawMidias.map((e) {
        final Map<String, dynamic> midia = Map<String, dynamic>.from(e);
        // Garante que os novos campos existam
        midia['qlik_integration'] = midia['qlik_integration'] ?? false;
        midia['url_externa'] = midia['url_externa'];
        midia['url_original'] = midia['url_original'];
        return midia.obs;
      }).toList(),
    );
  }

  Future<void> _playMediaNoIndice(int idx) async {
    if (_stopLoop.value) return; // se em algum momento pediram para parar, não fazemos nada

    if (midias.isEmpty) {
      existeMidia.value = false;
      isLoading.value = false;
      return;
    }

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

    isLoading.value = true;
    videoReady.value = false;

    if (m['tipo'] == 'video' && m['file'] != null) {
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
      await videoController!.initialize();

      isLoading.value = false;
      videoReady.value = true;
      await videoController!.play();
      videoController!.setVolume(1);
      await Future.delayed(videoController!.value.duration);

      if (!_stopLoop.value) {
        final int proximo = (currentIndex.value + 1) % midias.length;
        _playMediaNoIndice(proximo);
      }

    } else if (m['tipo'] == 'imagem') {
      // → Mostrar imagem por 20 segundos
      isWebview.value = false;
      isLoading.value = false;
      await Future.delayed(const Duration(seconds: 20));
      if (!_stopLoop.value) {
        final int proximo = (currentIndex.value + 1) % midias.length;
        _playMediaNoIndice(proximo);
      }

    } else if (m['tipo'] == 'url') {
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
        print('🌐 Carregando URL: $urlToLoad'); // Debug
        
        // Carregar URL com headers customizados para melhor compatibilidade
        await webview.loadRequest(
          Uri.parse(urlToLoad),
          headers: {
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'pt-BR,pt;q=0.9,en;q=0.8',
            'Accept-Encoding': 'gzip, deflate, br',
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache',
            'Upgrade-Insecure-Requests': '1',
          },
        );
        
        // Aguardar carregamento completo da página
        while (!webviewLoaded.value && !_stopLoop.value) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        
        // Executar configurações adicionais após o carregamento
        await _configurePageAfterLoad();
        
        isLoading.value = false;
        
        // Aguardar mais 5 segundos após o carregamento para garantir renderização completa e execução de scripts
        await Future.delayed(const Duration(seconds: 5));
        
        // Exibir por 115 segundos (120 total - 5 já aguardados = 2 minutos)
        await Future.delayed(const Duration(seconds: 115));
        
        if (!_stopLoop.value) {
          final int proximo = (currentIndex.value + 1) % midias.length;
          _playMediaNoIndice(proximo);
        }
      } else {
        // Se não conseguiu obter URL, pula para próxima mídia
        _showToast('URL inválida - pulando mídia');
        if (!_stopLoop.value) {
          final int proximo = (currentIndex.value + 1) % midias.length;
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