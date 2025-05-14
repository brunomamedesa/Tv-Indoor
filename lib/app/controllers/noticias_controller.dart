import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get/get.dart';

class NoticiasController extends GetxController{

  String newsUrl = "https://intranet.grupobig.com.br/api/painel/noticias-externas";
  final RxList<Map<String, dynamic>> news = <Map<String,dynamic>>[].obs;  
  final RxString loadingDots = ''.obs;

  Dio dio = Dio();

  @override
  Future<void> onInit() async {
    super.onInit();
    animateDots();
    await getNoticias();

  }

    Future<void> getNoticias() async {
    try {
      
      final response = await dio.get(newsUrl);
      final List<dynamic> listNews = response.data;
      news.value = List<Map<String, dynamic>>.from(listNews);
      // _startAutoScroll();

    } on DioException {
      news.value = [];
      return;
    }
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