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
    print('🌤️ WebviewController: Carregando previsão do tempo...');
    loading.value = true;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var prevEncoded = prefs.getString('previsao_tempo');
    print('🌤️ Previsão encontrada no SharedPreferences: $prevEncoded');
    
    if(prevEncoded != null) {
      try {
        previsaoTempo.value = jsonDecode(prevEncoded) ?? {};
        print('✅ Previsão decodificada com ${previsaoTempo.length} itens');
      } catch (e) {
        print('❌ Erro ao decodificar previsão: $e');
        previsaoTempo.value = {};
      }
    } else {
      print('⚠️ Nenhuma previsão encontrada no SharedPreferences');
      previsaoTempo.value = {};
    }
    loading.value = false;
  }

  Future<void> getMetais() async {
    print('🥇 WebviewController: Carregando cotação de metais...');
    loading.value = true;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var prevEncoded = prefs.getString('cotacao_metais');
    print('🥇 Cotação metais encontrada no SharedPreferences: $prevEncoded');
    
    if(prevEncoded != null) {
      try {
        cotacaoMetais.value = jsonDecode(prevEncoded) ?? {};
        print('✅ Cotação metais decodificada com ${cotacaoMetais.length} itens');
      } catch (e) {
        print('❌ Erro ao decodificar cotação metais: $e');
        cotacaoMetais.value = {};
      }
    } else {
      print('⚠️ Nenhuma cotação de metais encontrada no SharedPreferences');
      cotacaoMetais.value = {};
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