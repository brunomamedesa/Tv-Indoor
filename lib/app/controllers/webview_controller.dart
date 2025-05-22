import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebviewController extends GetxController {

  final RxList<dynamic> cotacoes = <dynamic>[].obs;
  final RxMap<String, dynamic> previsaoTempo = <String, dynamic>{}.obs;
  final RxBool loading = false.obs;

  final WebViewController webview = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..loadRequest(Uri.parse(
      'https://intraneth.grupobig.com.br/api/externo/shockmetais'
  ));


  @override
  Future<void> onInit() async {
    super.onInit();
    await getCotacoes();
    await getPrevisao();
  }

  Future<void> getCotacoes() async {
    loading.value = true;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var cotEncoded = prefs.getString('cotacoes');

    if(cotEncoded != null) {
      cotacoes.value = jsonDecode(cotEncoded);
    } 
    loading.value = false;
  }

  Future<void> getPrevisao() async {
    loading.value = true;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var prevEncoded = prefs.getString('previsao_tempo');

    if(prevEncoded != null) {
      previsaoTempo.value = jsonDecode(prevEncoded);
      print(previsaoTempo);
    } 
    loading.value = false;
  }


  

Widget svgAnimado(String urlSvg) {
  if (urlSvg == null || urlSvg.isEmpty) {
    // placeholder vazio do mesmo tamanho
    return const SizedBox(width: 0, height: 0);
  }
  final html = '''
  <!DOCTYPE html>
  <html style="background: transparent;">
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        html, body {
          margin: 0; padding: 0; overflow: hidden;
          background: transparent;
        }
      </style>
    </head>
    <body>
      <img src="$urlSvg" style="width:100%;height:100%;" />
    </body>
  </html>
  ''';

  final controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    // remove o fundo branco do WebView
    ..setBackgroundColor(const Color(0x00000000))
    ..loadRequest(
      Uri.dataFromString(
        html,
        mimeType: 'text/html',
        encoding: utf8,
      ),
    );


  return SizedBox(
    width: 60,
    height: 55,
    child: WebViewWidget(controller: controller),
  );
}


}