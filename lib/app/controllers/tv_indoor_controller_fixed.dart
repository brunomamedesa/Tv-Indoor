import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tv_indoor/app/controllers/config_controller.dart';
import 'package:tv_indoor/app/controllers/connectivity_controller.dart';
import 'package:tv_indoor/app/services/webview_cache_service.dart';
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
  Timer? _imageTimer;
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
            // Progresso do carregamento
          },
          onPageStarted: (String url) {
            webviewLoaded.value = false;
          },
          onPageFinished: (String url) {
            webviewLoaded.value = true;
          },
          onWebResourceError: (WebResourceError error) {
            print('🚨 WebView error: ${error.description}');
            print('🚨 Error type: ${error.errorType}');
            print('🚨 Failed URL: ${error.url}');
            webviewLoaded.value = true;
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      );

    // Configurar WebView
    await _configureWebViewSettings();
    
    // Carregar página em branco inicialmente
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

  // Configurar WebView
  Future<void> _configureWebViewSettings() async {
    try {
      print('🔧 Iniciando configuração do WebView...');
      
      if (Platform.isAndroid) {
        try {
          final cookieManager = WebViewCookieManager();
          await cookieManager.clearCookies();
          print('✅ Cookies limpos com sucesso');
        } catch (e) {
          print('⚠️ Erro ao limpar cookies: $e');
        }
      }

      try {
        await webview.runJavaScript('''
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

    // Limpar estado anterior
    isWebview.value = false;
    webviewLoaded.value = false;
    
    // Carregar página em branco para limpar WebView
    await webview.loadHtmlString('<html><body style="background:black;"></body></html>');
    await Future.delayed(const Duration(milliseconds: 300));

    // Garantir que o índice está dentro dos limites
    currentIndex.value = idx % midias.length;
    final m = midias[currentIndex.value];
    existeMidia.value = true;

    print('🎬 Tipo da mídia: ${m['tipo']}');
    print('🎬 URL/File: ${m['file'] ?? m['url']}');

    isLoading.value = true;
    videoReady.value = false;

    if (m['tipo'] == 'video' && m['file'] != null) {
      print('🎥 Reproduzindo vídeo: ${m['file']}');
      
      // Tocar vídeo
      isWebview.value = false;
      if (videoController != null) {
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
        
        // Aguardar duração do vídeo
        await Future.delayed(videoController!.value.duration);

        if (!_stopLoop.value) {
          final int proximo = (currentIndex.value + 1) % midias.length;
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
      
      // Mostrar imagem por 20 segundos
      isWebview.value = false;
      isLoading.value = false;
      
      await Future.delayed(const Duration(seconds: 20));
      
      if (!_stopLoop.value) {
        final int proximo = (currentIndex.value + 1) % midias.length;
        _playMediaNoIndice(proximo);
      }

    } else if (m['tipo'] == 'url') {
      print('🌐 Carregando URL: ${m['url']}');
      
      // Verificar conectividade
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

      // Limpar WebView
      isWebview.value = false;
      await webview.loadHtmlString('<html><body style="background:black;"></body></html>');
      await Future.delayed(const Duration(milliseconds: 500));
      
      isWebview.value = true;
      webviewLoaded.value = false;
      
      String? urlToLoad;
      
      if (m['qlik_integration'] == true) {
        // Buscar URL do Qlik
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
        urlToLoad = m['url_externa'] ?? m['url'];
      }
      
      if (urlToLoad != null) {
        currentWebviewUrl.value = urlToLoad;
        print('🌐 Carregando URL otimizada: $urlToLoad');

        try {
          isLoading.value = true;
          
          // Usar cache otimizado
          final cachedContent = await WebViewCacheService.getCachedContent(urlToLoad);
          
          await webview.loadHtmlString(
            cachedContent,
            baseUrl: urlToLoad,
          );
          
          print('✅ Conteúdo carregado do cache otimizado');
        } catch (e) {
          print('⚠️ Erro no cache, usando carregamento direto: $e');
          
          await webview.loadRequest(
            Uri.parse(urlToLoad),
            headers: {
              'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
              'Accept-Language': 'pt-BR,pt;q=0.9,en;q=0.8',
              'Accept-Encoding': 'gzip, deflate, br',
              'Cache-Control': 'max-age=3600',
              'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            },
          );
        }
        
        // Aguardar carregamento e otimizar
        try {
          await Future.delayed(const Duration(seconds: 2));
          
          await webview.runJavaScript('''
            try {
              // Remove elementos desnecessários
              var scripts = document.getElementsByTagName('script');
              for(var i = scripts.length - 1; i >= 0; i--) {
                if(scripts[i].src.includes('analytics') || 
                   scripts[i].src.includes('ads') ||
                   scripts[i].src.includes('tracking')) {
                  scripts[i].remove();
                }
              }
              
              // Desabilita interações
              document.body.style.pointerEvents = 'none';
              document.body.style.userSelect = 'none';
              
              // Otimiza imagens
              var images = document.getElementsByTagName('img');
              for(var i = 0; i < images.length; i++) {
                images[i].loading = 'lazy';
              }
              
              console.log('🚀 WebView otimizado para visualização');
            } catch(e) {
              console.log('Erro na otimização: ', e);
            }
          ''');
          
          webviewLoaded.value = true;
          isLoading.value = false;
          
        } catch (e) {
          print('Erro ao otimizar WebView: $e');
          webviewLoaded.value = true;
          isLoading.value = false;
        }
        
        // Aguardar 30 segundos e passar para próxima
        await Future.delayed(const Duration(seconds: 30));
        
        if (!_stopLoop.value) {
          final int proximo = (currentIndex.value + 1) % midias.length;
          _playMediaNoIndice(proximo);
        }
      } else {
        _showToast('URL inválida - pulando mídia');
        if (!_stopLoop.value) {
          final int proximo = (currentIndex.value + 1) % midias.length;
          _playMediaNoIndice(proximo);
        }
      }
    }
  }

  // Agenda próximo reload em 10 minutos
  void _scheduleNextReload() {
    _mediaTimer?.cancel();
    _mediaTimer = Timer(const Duration(minutes: 10), () {
      reload();
    });
  }

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
      );
    } catch (e) {
      print('Toast: $message');
    }
  }

  void _onError() {
    if (videoController?.value.hasError ?? false) {
      erroVideo.value = videoController!.value.errorDescription ?? 'Erro desconhecido no vídeo';
      print('❌ Erro no vídeo: ${erroVideo.value}');
    }
  }

  @override
  void onClose() {
    print('🔄 Fechando TvIndoorController...');
    _mediaTimer?.cancel();
    _imageTimer?.cancel();
    videoController?.dispose();
    super.onClose();
  }
}
