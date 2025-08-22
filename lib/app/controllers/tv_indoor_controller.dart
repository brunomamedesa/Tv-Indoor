
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
    
    // Inicializar WebView com configurações simples e estáveis
    webview = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..enableZoom(false) // Desabilitar zoom para evitar problemas de rendering
      ..setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            print('📊 WebView loading progress: $progress%');
          },
          onPageStarted: (String url) {
            print('🌐 WebView started loading: $url');
            webviewLoaded.value = false;
          },
          onPageFinished: (String url) {
            print('✅ WebView finished loading: $url');
            webviewLoaded.value = true;
            
            // Aguardar um pouco antes de marcar como carregado para garantir que o conteúdo seja renderizado
            Future.delayed(const Duration(seconds: 2), () {
              if (isWebview.value && webviewLoaded.value) {
                isLoading.value = false;
                print('✅ WebView completamente carregado e pronto');
              }
            });
          },
          onWebResourceError: (WebResourceError error) {
            print('🚨 WebView Resource Error:');
            print('   - Description: ${error.description}');
            print('   - Error Type: ${error.errorType}');
            print('   - Error Code: ${error.errorCode}');
            print('   - Failed URL: ${error.url}');
            
            // Só considerar como erro crítico se for um erro de rede ou timeout
            final isCriticalError = error.errorCode == -2 || // ERR_NAME_NOT_RESOLVED
                                   error.errorCode == -7 ||  // ERR_TIMED_OUT
                                   error.errorCode == -6 ||  // ERR_CONNECTION_REFUSED
                                   error.errorCode == -105;  // ERR_NAME_NOT_RESOLVED
            
            if (isCriticalError) {
              print('🚨 Erro crítico de rede detectado - pulando mídia');
              webviewLoaded.value = false;
              isLoading.value = false;
              
              Future.delayed(const Duration(seconds: 3), () {
                if (!_stopLoop.value && midias.isNotEmpty) {
                  final int proximo = (currentIndex.value + 1) % midias.length;
                  print('🚨 Pulando para próxima mídia devido a erro crítico: $proximo');
                  _playMediaNoIndice(proximo);
                }
              });
            } else {
              print('⚠️ Erro menor detectado - continuando carregamento');
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            print('🔀 Navigation request: ${request.url}');
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

  // Configurar WebView com configuração minimalista e estável
  Future<void> _configureWebViewSettings() async {
    try {
      print('🔧 Configurando WebView com configuração mínima...');
      
      // Executar apenas JavaScript essencial, sem modificações agressivas
      try {
        await webview.runJavaScript('''
          console.log("🚀 WebView inicializado com sucesso");
          
          // Configurar apenas essenciais para funcionamento
          if (typeof(Storage) !== "undefined") {
            console.log("✅ Storage disponível");
          }
          
          console.log("✅ WebView configurado minimamente");
        ''');
        print('✅ JavaScript básico executado');
      } catch (e) {
        print('⚠️ JavaScript não executado (normal para algumas páginas): $e');
      }
      
    } catch (e) {
      print('❌ Erro na configuração básica do WebView: $e');
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

    // Garantimos que o indice esteja dentro dos limites
    currentIndex.value = idx % midias.length;
    final m = midias[currentIndex.value];
    
    // MANTER existeMidia como true durante toda a transição
    existeMidia.value = true;

    print('🎬 Tipo da mídia: ${m['tipo']}');
    print('🎬 URL/File: ${m['file'] ?? m['url']}');

    // Definir isLoading ANTES de limpar estados para evitar flash
    isLoading.value = true;
    
    // Limpar estado anterior para transições suaves
    isWebview.value = false;
    webviewLoaded.value = false;
    videoReady.value = false;
    
    // Carregar página em branco para limpar WebView (sem delay)
    await webview.loadHtmlString('<html><body style="background:black;"></body></html>');

    // Timeout de segurança para loading infinito
    Timer(const Duration(seconds: 30), () {
      if (isLoading.value) {
        print('⏰ Timeout de loading - forçando reset');
        isLoading.value = false;
        if (!_stopLoop.value && midias.isNotEmpty) {
          final int proximo = (currentIndex.value + 1) % midias.length;
          _playMediaNoIndice(proximo);
        }
      }
    });

    if (m['tipo'] == 'video' && m['file'] != null) {
      print('🎥 Reproduzindo vídeo: ${m['file']}');
      print('🎥 Arquivo existe: ${File(m['file'] as String).existsSync()}');
      
      // → Tocar vídeo
      // ------------------------------------------------
      isWebview.value = false;
      if (videoController != null) {
        // Se já existia um controller anterior, descarte-o
        await videoController!.dispose();
        videoController = null;
        print('🎥 Controller anterior descartado');
      }

      final videoFile = File(m['file'] as String);
      if (!videoFile.existsSync()) {
        print('❌ Arquivo de vídeo não encontrado: ${m['file']}');
        isLoading.value = false;
        if (!_stopLoop.value) {
          final int proximo = (currentIndex.value + 1) % midias.length;
          _playMediaNoIndice(proximo);
        }
        return;
      }

      videoController = VideoPlayerController.file(videoFile)
        ..addListener(_onError);
      
      try {
        print('🎥 Inicializando VideoPlayerController...');
        await videoController!.initialize();
        
        print('🎥 Controller inicializado com sucesso');
        print('🎥 Duração: ${videoController!.value.duration}');
        print('🎥 Tamanho: ${videoController!.value.size}');
        print('🎥 AspectRatio: ${videoController!.value.aspectRatio}');

        isLoading.value = false;
        videoReady.value = true;
        
        print('🎥 Iniciando reprodução...');
        await videoController!.play();
        videoController!.setVolume(1);
        
        print('🎥 Vídeo iniciado - aguardando finalização...');
        
        await Future.delayed(videoController!.value.duration);

        if (!_stopLoop.value) {
          final int proximo = (currentIndex.value + 1) % midias.length;
          print('🎥 Vídeo finalizado - próximo índice: $proximo');
          _playMediaNoIndice(proximo);
        }
      } catch (e) {
        print('❌ Erro ao reproduzir vídeo: $e');
        print('❌ Tipo do erro: ${e.runtimeType}');
        isLoading.value = false;
        videoReady.value = false;
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
        // APENAS agora definir isWebview como true, após ter uma URL válida
        isWebview.value = true;
        currentWebviewUrl.value = urlToLoad;
        print('🌐 Carregando URL: $urlToLoad');
        
        try {
          // Primeiro, carregar a URL de forma simples
          await webview.loadRequest(
            Uri.parse(urlToLoad),
          ).timeout(const Duration(seconds: 20)); // Timeout reduzido para 20 segundos
          
          print('✅ URL carregada com sucesso');
          
          // Aguardar um tempo adequado para o conteúdo carregar
          await Future.delayed(const Duration(seconds: 3));
          
          // Aplicar apenas otimizações mínimas que NÃO quebram funcionalidades
          await webview.runJavaScript('''
            try {
              console.log('🔧 Aplicando otimizações mínimas...');
              
              // Apenas configurar zoom se necessário
              try {
                var viewport = document.querySelector('meta[name="viewport"]');
                if (!viewport) {
                  viewport = document.createElement('meta');
                  viewport.name = 'viewport';
                  viewport.content = 'width=device-width, initial-scale=0.9, user-scalable=yes';
                  if (document.head) {
                    document.head.appendChild(viewport);
                  }
                }
              } catch(e) {
                console.log('Viewport não pôde ser configurado:', e);
              }
              
              // Remover apenas elementos de publicidade óbvios (sem quebrar BI)
              try {
                var adsSelectors = [
                  'iframe[src*="doubleclick"]',
                  'iframe[src*="googlesyndication"]', 
                  'div[class*="advertisement"]',
                  'div[id*="google_ads"]'
                ];
                
                adsSelectors.forEach(function(selector) {
                  var elements = document.querySelectorAll(selector);
                  elements.forEach(function(el) { 
                    if (el) el.style.display = 'none'; 
                  });
                });
              } catch(e) {
                console.log('Ads não puderam ser removidos:', e);
              }
              
              console.log('✅ Otimizações aplicadas com sucesso');
            } catch(e) {
              console.log('⚠️ Erro nas otimizações (ignorado):', e);
            }
          ''').catchError((error) {
            print('⚠️ JavaScript de otimização falhou (ignorado): $error');
          });
          
          // Marcar como carregado apenas após todas as operações
          if (!webviewLoaded.value) {
            webviewLoaded.value = true;
            isLoading.value = false;
          }
          
        } catch (e) {
          print('❌ Erro ao carregar URL: $e');
          webviewLoaded.value = false;
          isLoading.value = false;
          
          // Em caso de erro, aguardar um pouco e pular para próxima mídia
          await Future.delayed(const Duration(seconds: 3));
          
          if (!_stopLoop.value) {
            final int proximo = (currentIndex.value + 1) % midias.length;
            print('❌ Erro no WebView - próximo índice: $proximo');
            _playMediaNoIndice(proximo);
            return; // Sair da função para não aguardar os 4 minutos
          }
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
        isLoading.value = false;
        isWebview.value = false; // Resetar estado do WebView
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
      final errorDesc = videoController!.value.errorDescription;
      print('❌ Erro no VideoPlayerController: $errorDesc');
      erroVideo.value = 'Erro ao reproduzir: $errorDesc';
      
      // Se há erro, marcar como não pronto e tentar próxima mídia
      videoReady.value = false;
      isLoading.value = false;
      
      if (!_stopLoop.value && midias.isNotEmpty) {
        final int proximo = (currentIndex.value + 1) % midias.length;
        print('❌ Erro detectado - pulando para próxima mídia: $proximo');
        Future.delayed(const Duration(seconds: 1), () {
          _playMediaNoIndice(proximo);
        });
      }
    }
  }

  @override
  void onClose() {
    _mediaTimer?.cancel();
    videoController?.dispose();
    super.onClose();
  }
}