
import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
  final RxInt _currentIndex = 0.obs;

  Timer? _mediaTimer;
  Dio dio = Dio();
  VideoPlayerController? videoController;
  

  Map<String, dynamic> get mediaAtual => midias.isEmpty ? {} : midias[_currentIndex.value];


  @override
  Future<void> onInit() async {
    super.onInit();
    await getMidias();
    print('Midias on init:: $midias');
    if(midias.isNotEmpty){
      _playNext();
    }
  }

  Future<void> getMidias() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final midiaEncode =  prefs.getString('midias');
    midias.assignAll(
      (jsonDecode(midiaEncode!) as List).map((e) => Map<String, dynamic>.from(e).obs).toList()
    );

  }

  Future<void> _playNext() async {
    if (midias.isEmpty) return;
    final m = mediaAtual;
    
    await videoController?.dispose();
    if (m['tipo'] == 'video' && m['url'].toString().endsWith('.mp4') ) {
      print('video: $m');
      videoController = VideoPlayerController.file(File(m['file']));
      await videoController!.initialize();
      videoController!.setVolume(1);
      videoController!.play();
      videoController!.addListener(() {
        if (videoController!.value.hasError) {
            erroVideo.value =
                'Erro ao reproduzir o vídeo: ${videoController!.value.errorDescription}';
        }
      });
      
      await Future.delayed(videoController!.value.duration);

    } else {
      print('imagem: $m');
      await Future.delayed(const Duration(seconds: 8));

    }

    _advanceIndex();
    _playNext(); 
  }

  void _advanceIndex() {
    _currentIndex.value = (_currentIndex.value + 1) % midias.length;
  }

  @override
  void onClose() {
    _mediaTimer?.cancel();
    videoController?.dispose();
    super.onClose();
  }
}