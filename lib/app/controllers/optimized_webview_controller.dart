import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/material.dart';
import 'package:tv_indoor/app/services/webview_cache_service.dart';

class OptimizedWebViewController extends GetxController {
  late WebViewController webViewController;
  final isLoading = true.obs;
  final hasError = false.obs;
  final loadingProgress = 0.0.obs;
  
  @override
  void onInit() {
    super.onInit();
    _initializeWebView();
  }
  
  void _initializeWebView() {
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      // Otimizações para performance
      ..setUserAgent('Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36')
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            isLoading.value = true;
            hasError.value = false;
            loadingProgress.value = 0.0;
          },
          onProgress: (int progress) {
            loadingProgress.value = progress / 100.0;
          },
          onPageFinished: (String url) {
            isLoading.value = false;
            loadingProgress.value = 1.0;
            // Remove elementos desnecessários para visualização
            _removeUnnecessaryElements();
          },
          onWebResourceError: (WebResourceError error) {
            hasError.value = true;
            isLoading.value = false;
            print('Erro WebView: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            // Bloqueia navegações desnecessárias
            if (request.url.contains('ads') || 
                request.url.contains('analytics') ||
                request.url.contains('tracking')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
  }
  
  Future<void> loadUrlWithCache(String url) async {
    try {
      isLoading.value = true;
      hasError.value = false;
      
      // Tenta carregar do cache primeiro
      final cachedContent = await WebViewCacheService.getCachedContent(url);
      
      // Carrega o conteúdo otimizado
      await webViewController.loadHtmlString(
        cachedContent,
        baseUrl: url,
      );
      
    } catch (e) {
      print('Erro ao carregar URL com cache: $e');
      hasError.value = true;
      
      // Fallback: carrega diretamente
      try {
        await webViewController.loadRequest(
          Uri.parse(url),
        ).timeout(const Duration(seconds: 30));
      } catch (timeoutError) {
        print('Timeout ao carregar URL: $timeoutError');
        hasError.value = true;
      }
    } finally {
      isLoading.value = false;
    }
  }
  
  void _removeUnnecessaryElements() {
    // Remove elementos que não são necessários para visualização
    webViewController.runJavaScript('''
      try {
        // Remove scripts desnecessários
        var scripts = document.getElementsByTagName('script');
        for(var i = scripts.length - 1; i >= 0; i--) {
          if(scripts[i].src.includes('analytics') || 
             scripts[i].src.includes('ads') ||
             scripts[i].src.includes('tracking') ||
             scripts[i].src.includes('facebook') ||
             scripts[i].src.includes('google-analytics')) {
            scripts[i].remove();
          }
        }
        
        // Remove elementos interativos
        var buttons = document.getElementsByTagName('button');
        for(var i = 0; i < buttons.length; i++) {
          buttons[i].style.pointerEvents = 'none';
          buttons[i].disabled = true;
        }
        
        var links = document.getElementsByTagName('a');
        for(var i = 0; i < links.length; i++) {
          links[i].style.pointerEvents = 'none';
          links[i].onclick = function(e) { e.preventDefault(); return false; };
        }
        
        // Remove formulários
        var forms = document.getElementsByTagName('form');
        for(var i = 0; i < forms.length; i++) {
          forms[i].style.display = 'none';
        }
        
        // Otimiza imagens
        var images = document.getElementsByTagName('img');
        for(var i = 0; i < images.length; i++) {
          images[i].loading = 'lazy';
          images[i].style.maxWidth = '100%';
          images[i].style.height = 'auto';
        }
        
        // Remove elementos de publicidade
        var adsSelectors = ['.ads', '[class*="ad-"]', '[id*="ad-"]', '.popup', '.modal'];
        adsSelectors.forEach(function(selector) {
          var elements = document.querySelectorAll(selector);
          elements.forEach(function(el) { el.style.display = 'none'; });
        });
        
        // Desabilita scroll horizontal
        document.body.style.overflowX = 'hidden';
        document.documentElement.style.overflowX = 'hidden';
        
        console.log('WebView otimizado para visualização');
      } catch(e) {
        console.log('Erro na otimização: ' + e);
      }
    ''');
  }
  
  void reload() {
    webViewController.reload();
  }
  
  Future<void> clearCache() async {
    await WebViewCacheService.clearCache();
  }
}
