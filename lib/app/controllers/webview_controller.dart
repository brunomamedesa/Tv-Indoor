import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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


  

Widget svgAnimado(String? urlSvg) {
  // mantém o mesmo tamanho que você usava no WebView
  const double w = 60, h = 55;

  if (urlSvg == null || urlSvg.isEmpty) {
    // placeholder vazio do mesmo tamanho
    return const SizedBox(width: w, height: h);
  }

  return SvgPicture.network(
    urlSvg,
    width: w,
    height: h,
    fit: BoxFit.contain,
    placeholderBuilder: (context) => const SizedBox(
      width: w,
      height: h,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      ),
    ),
    // você pode remover `color` se quiser manter as cores originais do SVG
    color: Colors.white,
  );
}


}