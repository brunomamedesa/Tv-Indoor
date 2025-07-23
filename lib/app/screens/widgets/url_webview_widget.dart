import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tv_indoor/app/controllers/tv_indoor_controller.dart';
import 'package:webview_flutter/webview_flutter.dart';

class UrlWebviewWidget extends StatelessWidget {
  const UrlWebviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final TvIndoorController controller = Get.find();
    
    return Obx(() {
      if (controller.currentWebviewUrl.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
      
      return WebViewWidget(
        controller: controller.webview,
      );
    });
  }
}
