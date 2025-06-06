import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NoticiasController extends GetxController{

  final RxList<dynamic> news = <dynamic>[].obs; 
  final RxInt currentIndex = 0.obs; 
  final RxString loadingDots = ''.obs;
  final RxInt qtdNoticias = 0.obs;

  Dio dio = Dio();

  @override
  Future<void> onInit() async {
    super.onInit();
    animateDots();
    await getNoticias();
    _iniciarCicloDeNoticias();
  }

    Future<void> getNoticias() async {
      try {

        final prefs = await SharedPreferences.getInstance();
        final encoded = prefs.getString('noticias');
        if (encoded != null) {
          news.value = jsonDecode(encoded);

        } else {
          news.clear();
        }

        qtdNoticias.value = news.length;
         
      } catch (e) {
        print('Erro ao carregar notícias: $e');
        news.clear();
        qtdNoticias.value = 0;
      }
  }

  void _iniciarCicloDeNoticias() {

    // Laço assíncrono que nunca empilha recursão
    Future.doWhile(() async {

      await Future.delayed(const Duration(seconds: 20));
      if (qtdNoticias.value > 0) nextIndex();
      return true; 

    });

  }

  void nextIndex() {
    currentIndex.value = (currentIndex.value + 1) % max(1, qtdNoticias.value);
  }

  void animateDots(){

    Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (news.isNotEmpty) {
        timer.cancel();

      } else {

        if (loadingDots.value.length < 3) {
          loadingDots.value += '.';
        } else {
          loadingDots.value = '';
        }
      }

    });
  }
}