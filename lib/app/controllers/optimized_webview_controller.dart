import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

class OptimizedWebViewController extends GetxController {
  
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxDouble loadingProgress = 0.0.obs;
  final RxString currentUrl = ''.obs;
  
  late final WebViewController webViewController;
  Timer? _timeoutTimer;
  
  @override
  void onInit() {
    super.onInit();
    _initializeWebView();
  }
  
  void _initializeWebView() {
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..enableZoom(true)
      ..setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            loadingProgress.value = progress / 100.0;
          },
          onPageStarted: (String url) {
            print('🌐 Iniciando carregamento: $url');
            isLoading.value = true;
            hasError.value = false;
            loadingProgress.value = 0.0;
            currentUrl.value = url;
          },
          onPageFinished: (String url) {
            print('✅ Página carregada: $url');
            isLoading.value = false;
            loadingProgress.value = 1.0;
            _cancelTimeout();
            _configurePageAfterLoad();
          },
          onWebResourceError: (WebResourceError error) {
            print('❌ Erro no WebView: ${error.description}');
            hasError.value = true;
            isLoading.value = false;
            _cancelTimeout();
            
            // Tentar recarregar automaticamente após erro
            Future.delayed(const Duration(seconds: 3), () {
              if (hasError.value && currentUrl.value.isNotEmpty) {
                print('🔄 Tentando recarregar após erro...');
                loadUrlWithCache(currentUrl.value);
              }
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            print('🔗 Navegação solicitada: ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      );

    // Configurações específicas para Android
    if (Platform.isAndroid) {
      _configureAndroidWebView();
    }
  }
  
  Future<void> _configureAndroidWebView() async {
    try {
      // Configurações adicionais para Android se necessário
      await webViewController.runJavaScript('''
        // Configurações básicas para melhor compatibilidade
        window.addEventListener('error', function(e) {
          console.log('JavaScript Error:', e.message);
        });
      ''');
    } catch (e) {
      print('Erro ao configurar WebView Android: $e');
    }
  }
  
  Future<void> loadUrlWithCache(String url) async {
    if (url.isEmpty) {
      print('⚠️ URL vazia fornecida');
      return;
    }
    
    try {
      print('🔄 Carregando URL: $url');
      isLoading.value = true;
      hasError.value = false;
      loadingProgress.value = 0.0;
      currentUrl.value = url;
      
      // Configurar timeout
      _startTimeout();
      
      await webViewController.loadRequest(Uri.parse(url));
      
    } catch (e) {
      print('❌ Erro ao carregar URL: $e');
      hasError.value = true;
      isLoading.value = false;
      _cancelTimeout();
    }
  }
  
  void _startTimeout() {
    _cancelTimeout();
    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (isLoading.value) {
        print('⏱️ Timeout ao carregar página');
        hasError.value = true;
        isLoading.value = false;
      }
    });
  }
  
  void _cancelTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }
  
  Future<void> _configurePageAfterLoad() async {
    try {
      // Injetar JavaScript para melhorar a experiência
      await webViewController.runJavaScript('''
        // Remover barras de rolagem se necessário
        document.body.style.overflow = 'hidden';
        
        // Otimizações de performance
        if (typeof window.performance !== 'undefined') {
          window.performance.mark('page-loaded');
        }
        
        // Configurar viewport para dispositivos móveis com zoom fixo de 80%
        var viewport = document.querySelector('meta[name="viewport"]');
        var zoomValue = 0.8;
        var maxZoom = 3.0;
        var widthCompensation = '125%'; // 100/0.8 = 125%
        
        if (!viewport) {
          viewport = document.createElement('meta');
          viewport.name = 'viewport';
          viewport.content = 'width=device-width, initial-scale=' + zoomValue + ', maximum-scale=' + maxZoom + ', user-scalable=yes';
          document.head.appendChild(viewport);
        } else {
          // Atualizar viewport existente
          viewport.content = 'width=device-width, initial-scale=' + zoomValue + ', maximum-scale=' + maxZoom + ', user-scalable=yes';
        }
        
        // Aplicar zoom via CSS Transform
        document.body.style.transform = 'scale(' + zoomValue + ')';
        document.body.style.transformOrigin = '0 0';
        document.body.style.width = widthCompensation;
      ''');
      
      print('✅ Configurações pós-carregamento aplicadas');
    } catch (e) {
      print('⚠️ Erro ao aplicar configurações pós-carregamento: $e');
    }
  }
  
  Future<void> reload() async {
    if (currentUrl.value.isNotEmpty) {
      await loadUrlWithCache(currentUrl.value);
    } else {
      await webViewController.reload();
    }
  }
  
  Future<void> clearCache() async {
    try {
      await webViewController.clearCache();
      await webViewController.clearLocalStorage();
      print('🧹 Cache limpo');
    } catch (e) {
      print('⚠️ Erro ao limpar cache: $e');
    }
  }
  
  @override
  void onClose() {
    _cancelTimeout();
    super.onClose();
  }
}