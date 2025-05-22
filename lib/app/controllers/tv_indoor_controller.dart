
import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tv_indoor/app/controllers/config_controller.dart';
import 'package:video_player/video_player.dart';




class TvIndoorController extends GetxController {
  
  final RxList<Map<String, dynamic>> news = <Map<String,dynamic>>[].obs;
  final RxString loadingDots = ''.obs;
  final RxMap<String, dynamic> arquivoAtual = <String, dynamic>{}.obs;
  final RxString erroVideo = ''.obs;
  final RxString deviceId = ''.obs;
  final RxList<RxMap<String, dynamic>> midias = <RxMap<String, dynamic>>[].obs;
  final RxInt currentIndex = 0.obs;
  final RxBool isLoading = false.obs;
  final RxMap<String, dynamic> mediaAtual = <String, dynamic>{}.obs;
  final RxBool existeMidia = false.obs;

  Timer? _mediaTimer;
  Dio dio = Dio();
  bool _stopLoop = false;
  Future<void>? _loopFuture;


  VideoPlayerController? videoController;
  
  @override
  Future<void> onInit() async {
    super.onInit();
    isLoading.value = true;
    getTempoAtualizacao();
    _stopLoop = false;
    _loopFuture = _playLoop();
  }

  Future<void> reload() async {
    isLoading.value = true;
    _stopLoop = true;
    ConfigController configController = Get.find<ConfigController>();
    await configController.refreshData();

    currentIndex.value = 0;

    await getMidias();
    _stopLoop = false;
    // reinicia o loop
    _loopFuture = _playLoop();
    getTempoAtualizacao();
    isLoading.value = false;
  }

  Future<void> getMidias() async {

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final midiaEncode =  prefs.getString('midias');
    midias.assignAll(
      (jsonDecode(midiaEncode!) as List).map((e) => Map<String, dynamic>.from(e).obs).toList()
    );

  }

Future<void> _playLoop() async {
    await getMidias();
    if (midias.isEmpty) {
      isLoading.value = false;
      existeMidia.value = false;
      return;
    }
    while (!_stopLoop) {
      final m = midias[currentIndex.value];
      existeMidia.value = true;
      isLoading.value = true;

      if (m['tipo'] == 'video' && m['file'] != null) {
        await _playVideo(File(m['file'] as String));
      } else {
        // imagem
        isLoading.value = false;
        await Future.delayed(const Duration(seconds: 20));
      }

      // próximo índice
      currentIndex.value = (currentIndex.value + 1) % midias.length;
    }
  }

  Future<void> getTempoAtualizacao() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final timer = prefs.getString('tempo_atualizacao');

    iniciaTimer(int.parse(timer!));
  } 

  void iniciaTimer(int minutes) {
    _mediaTimer?.cancel();
    _mediaTimer = Timer(Duration(minutes: minutes), () {
      reload();
    });
  }

  Future<void> _playVideo(File file) async {
    // limpa o anterior
    if (videoController != null) {
      await videoController!.pause();
      videoController!.removeListener(_onError);
      await videoController!.dispose();
    }

    videoController = VideoPlayerController.file(file)
      ..addListener(_onError);
    await videoController!.initialize();
    isLoading.value = false;
    await videoController!.play();
    videoController!.setVolume(1);
    await Future.delayed(videoController!.value.duration);
  }

  void _onError() {
    if (videoController?.value.hasError ?? false) {
      erroVideo.value =
          'Erro ao reproduzir: ${videoController!.value.errorDescription}';
    }
  }

  @override
  void onClose() {
    _mediaTimer?.cancel();
    videoController?.dispose();
    super.onClose();
  }
}