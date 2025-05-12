
import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:mobile_device_identifier/mobile_device_identifier.dart';




class TvIndoorController extends GetxController {
  
  final RxList<Map<String, dynamic>> news = <Map<String,dynamic>>[].obs;
  final RxString loadingDots = ''.obs;
  final RxMap<String, dynamic> arquivoAtual = <String, dynamic>{}.obs;
  final RxString erroVideo = ''.obs;
  final RxString deviceId = ''.obs;
  final RxList<RxMap<String, dynamic>> midias = <RxMap<String, dynamic>>[].obs;

  // final List<String> midias = [
  //   'assets/midias/img1.jpeg',
  //   'assets/midias/img2.jpeg',
  //   'assets/midias/videoplayback.mp4',
  // ];


  Dio dio = Dio();
  final ScrollController scrollController = ScrollController();
  Timer? _scrollTimer;
  VideoPlayerController? videoController;
  late String imagemAtual = 'assets/midias/img1.jpeg';

  @override
  Future<void> onInit() async {
    super.onInit();
    getMidias();
  }

  Future<void> getMidias() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final midiaEncode =  prefs.getString('midias');
    midias.value = jsonDecode(midiaEncode!);
    print(midias);

    while (true) {

      for (var midia in midias) {

        print(midia);
        // if (midia.endsWith('.mp4')) {
        //   print(midia);
        //   videoController = VideoPlayerController.asset(midia);
        //   print(videoController);
        //   await videoController!.initialize();

        //   arquivoAtual.value = {'tipo': 'video', 'path': midia};

        //   videoController!.setVolume(1);
        //   videoController!.play(); 

        //   // Inicia a reprodução do vídeo
        //   videoController!.addListener(() {

        //     if (videoController!.value.hasError) {
        //         erroVideo.value =
        //             'Erro ao reproduzir o vídeo: ${videoController!.value.errorDescription}';
        //     }

        //   });

        //   await Future.delayed(
        //       videoController!.value.duration); // Espera a duração do vídeo
          
        //   await videoController!.dispose();

        // } else {

        //   imagemAtual = midia;
        //   print(midia);
        //   arquivoAtual.value = {'tipo': 'imagem', 'path': midia};

        //   await Future.delayed(
        //       const Duration(seconds: 8)); // Tempo para exibir cada imagem
        // }

      }
    }
  }

}