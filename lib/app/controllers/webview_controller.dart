import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebviewController extends GetxController {

  final RxList<dynamic> cotacoes = <dynamic>[].obs;
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

}