
import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:mobile_device_identifier/mobile_device_identifier.dart';




class TvIndoorController extends GetxController {
  
  final RxList<Map<String, dynamic>> news = <Map<String,dynamic>>[].obs;
  final RxString loadingDots = ''.obs;
  final RxMap<String, dynamic> arquivoAtual = <String, dynamic>{}.obs;
  final RxString erroVideo = ''.obs;
  final RxBool isWebView = false.obs;
  final RxString deviceId = ''.obs;


  final List<String> midias = [
    'assets/midias/img1.jpeg',
    'assets/midias/img2.jpeg',
    'assets/midias/videoplayback.mp4',
  ];

  final WebViewController webview = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..loadRequest(Uri.parse(
      'https://intraneth.grupobig.com.br/api/externo/shockmetais'
  ));
  String newsUrl = "https://intranet.grupobig.com.br/api/painel/noticias-externas";
  Dio dio = Dio();
  final ScrollController scrollController = ScrollController();
  Timer? _scrollTimer;
  VideoPlayerController? videoController;
  late String imagemAtual = 'assets/midias/img1.jpeg';



  @override
  Future<void> onInit() async {
    super.onInit();
    animateDots();
    await getNoticias();
    await getDeviceId();
    await getMidias();
  }

  Future<void> getDeviceId() async{
    deviceId.value = (await MobileDeviceIdentifier().getDeviceId())!;
    print('Dispositivo: ${deviceId.value}');
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


  Future<void> getNoticias() async {
    try {
      
      final response = await dio.get(newsUrl);
      final List<dynamic> listNews = response.data;
      news.value = List<Map<String, dynamic>>.from(listNews);
      _startAutoScroll();

    } on DioException catch (e) {
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

  Future<void> getMidias() async {
        


    while (true) {

      for (var midia in midias) {

        if (midia.endsWith('.mp4')) {
          print(midia);
          videoController = VideoPlayerController.asset(midia);
          print(videoController);
          await videoController!.initialize();

          arquivoAtual.value = {'tipo': 'video', 'path': midia};

          videoController!.setVolume(1);
          videoController!.play(); 

          // Inicia a reprodução do vídeo
          videoController!.addListener(() {

            if (videoController!.value.hasError) {
                erroVideo.value =
                    'Erro ao reproduzir o vídeo: ${videoController!.value.errorDescription}';
            }

          });

          await Future.delayed(
              videoController!.value.duration); // Espera a duração do vídeo
          
          await videoController!.dispose();

        } else {

          imagemAtual = midia;
          print(midia);
          arquivoAtual.value = {'tipo': 'imagem', 'path': midia};

          await Future.delayed(
              const Duration(seconds: 8)); // Tempo para exibir cada imagem
        }

      }
    }
  }

}