import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:tv_indoor/app/controllers/optimized_webview_controller.dart';

class OptimizedWebViewWidget extends StatelessWidget {
  final String url;
  final Duration timeout;
  final bool showLoadingProgress;
  
  const OptimizedWebViewWidget({
    Key? key,
    required this.url,
    this.timeout = const Duration(seconds: 30),
    this.showLoadingProgress = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OptimizedWebViewController(), tag: url);
    
    // Carrega a URL quando o widget é construído
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (url.isNotEmpty) {
        controller.loadUrlWithCache(url);
      }
    });
    
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // WebView
          WebViewWidget(controller: controller.webViewController),
          
          // Loading overlay com progresso
          Obx(() => controller.isLoading.value
              ? _buildLoadingOverlay(controller)
              : const SizedBox.shrink()),
          
          // Error overlay
          Obx(() => controller.hasError.value
              ? _buildErrorWidget(controller)
              : const SizedBox.shrink()),
        ],
      ),
    );
  }
  
  Widget _buildLoadingOverlay(OptimizedWebViewController controller) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            const Text(
              'Carregando conteúdo...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            if (showLoadingProgress) ...[
              const SizedBox(height: 16),
              Obx(() => Container(
                width: 200,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: controller.loadingProgress.value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              )),
              const SizedBox(height: 8),
              Obx(() => Text(
                '${(controller.loadingProgress.value * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorWidget(OptimizedWebViewController controller) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Erro ao carregar conteúdo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tentando novamente...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                controller.hasError.value = false;
                controller.loadUrlWithCache(url);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
