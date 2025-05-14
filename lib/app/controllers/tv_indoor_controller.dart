
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';




class TvIndoorController extends GetxController {
  
  final RxList<Map<String, dynamic>> news = <Map<String,dynamic>>[].obs;
  final RxString loadingDots = ''.obs;
  final RxMap<String, dynamic> arquivoAtual = <String, dynamic>{}.obs;
  final RxString erroVideo = ''.obs;
  final RxString deviceId = ''.obs;
  final RxList<RxMap<String, dynamic>> midias = <RxMap<String, dynamic>>[].obs;
  final RxInt _currentIndex = 0.obs;
  final RxBool isLoading = false.obs;
  final RxMap<String, dynamic> mediaAtual = <String, dynamic>{}.obs;
  final RxBool existeMidia = false.obs;

  Timer? _mediaTimer;
  Dio dio = Dio();
  VideoPlayerController? videoController;
  
  @override
  Future<void> onInit() async {
    super.onInit();
    isLoading.value = true;
    await getMidias();
    _playNext();
  }

  Future<void> reload() async {
    print('a');
    isLoading.value = true;
    await getMidias();
    _playNext();
  }

  Future<void> getMidias() async {

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final midiaEncode =  prefs.getString('midias');
    midias.assignAll(
      (jsonDecode(midiaEncode!) as List).map((e) => Map<String, dynamic>.from(e).obs).toList()
    );

    print('midias: $midias');
  }

  Future<void> _playNext() async {

    if (midias.isEmpty) {
      isLoading.value = false;
      existeMidia.value = false;
      return;
    } 
    
    existeMidia.value = true;
    mediaAtual.value = midias[_currentIndex.value];
    
    isLoading.value = true;
    final m = mediaAtual;
    
    await videoController?.dispose();

    if (m['tipo'] == 'video' && m['url'].toString().endsWith('.mp4') ) {

      videoController = VideoPlayerController.file(File(m['file']));
      await videoController!.initialize();
      videoController!.setVolume(1);
      videoController!.play();
      isLoading.value = false; //Se estiver com loading, após inicializar a midia já para-lo

      videoController!.addListener(() {
        if (videoController!.value.hasError) {
            erroVideo.value =
                'Erro ao reproduzir o vídeo: ${videoController!.value.errorDescription}';
        }
      });
      
      await Future.delayed(videoController!.value.duration);

    } else {
      
      isLoading.value = false;
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