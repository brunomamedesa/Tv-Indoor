import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebviewController extends GetxController {

  final RxList<dynamic> cotacoes = <dynamic>[].obs;
  final RxMap<String, dynamic> previsaoTempo = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> cotacaoMetais = <String, dynamic>{}.obs;
  final RxBool loading = false.obs;
  final RxString versao = ''.obs;



  @override
  Future<void> onInit() async {
    super.onInit();
    await getCotacoes();
    await getMetais();
    await getPrevisao();
    await getAppVersion();
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
    print('previsao: $prevEncoded');
    if(prevEncoded != null) {
      previsaoTempo.value = jsonDecode(prevEncoded) ?? {};
    } 
    loading.value = false;
  }

  Future<void> getMetais() async {
    loading.value = true;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var prevEncoded = prefs.getString('cotacao_metais');
    if(prevEncoded != null) {
      cotacaoMetais.value = jsonDecode(prevEncoded) ?? {};
    } 
    loading.value = false;
  }

  Future<void> getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final version = packageInfo.version;       // ex: "1.2.3"
    versao.value = version;
  }

  

Widget svgAnimado(String? urlSvg) {
  // mantém o mesmo tamanho que você usava no WebView
  const double w = 55, h = 45;

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
          color: Colors.blue,
        ),
      ),
    ),
    // você pode remover `color` se quiser manter as cores originais do SVG
    // color: Colors.black,
  );
}


}