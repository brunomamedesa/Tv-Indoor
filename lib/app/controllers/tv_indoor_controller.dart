
import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TvIndoorController extends GetxController {
  
  final RxList<Map<String, dynamic>> news = <Map<String,dynamic>>[].obs;
  final RxString loadingDots = ''.obs;


  String newsUrl = "https://intranet.grupobig.com.br/api/painel/noticias-externas";
  Dio dio = Dio();
  final ScrollController scrollController = ScrollController();
  Timer? _scrollTimer;

  @override
  Future<void> onInit() async {
    super.onInit();
    animateDots();
    await getNoticias();
  }

  void animateDots(){
    Timer.periodic(const Duration(milliseconds: 700), (timer) {
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


  Future<void> getNoticias() async {
    try {
      
      final response = await dio.get(newsUrl);
      print(response.data);
      final List<dynamic> jsonNews = response.data;
      news.value = jsonNews.map((json) => json as Map<String, dynamic>).toList();



    } on DioException catch (e) {
      print(e.response);
      news.value = [];
      return;
    }
  }

    void _startAutoScroll() {

      _scrollTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {

        if (scrollController.hasClients) {

          double maxScroll = scrollController.position.maxScrollExtent;
          double currentScroll = scrollController.offset;

          if (currentScroll < maxScroll) {

            scrollController.jumpTo(currentScroll + 1);

          } else {

            scrollController.jumpTo(0);

          }

        }

      });
    }

}