import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebviewController extends GetxController {
  final WebViewController webview = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..loadRequest(Uri.parse(
      'https://intraneth.grupobig.com.br/api/externo/shockmetais'
  ));
}