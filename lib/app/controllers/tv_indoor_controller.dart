
import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tv_indoor/app/controllers/config_controller.dart';
import 'package:tv_indoor/app/controllers/webview_controller.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';




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
  final RxBool isWebview = false.obs;

  Timer? _mediaTimer;
  Dio dio = Dio();

  RxBool _stopLoop = false.obs;
  Timer? _imageTimer; // usado para cancelar facilmente o “delay de imagem”
  VideoPlayerController? videoController;
  final RxBool videoReady = false.obs;


  final WebViewController webview = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..loadRequest(Uri.parse(
      'https://intraneth.grupobig.com.br/api/externo/shockmetais'
  ));
  
  @override
  Future<void> onInit() async {
    super.onInit();
    isLoading.value = true;
    getTempoAtualizacao();
    _stopLoop.value = false;
    await getMidias();

    if (midias.isNotEmpty) {
       existeMidia.value = true;
       currentIndex.value = 0;
      _playMediaNoIndice(currentIndex.value);
    } else {
      existeMidia.value = false;
      isLoading.value = false;
    }

  }

  Future<void> reload() async {
    isLoading.value = true;
    // 1) sinalize que deve parar imediatamente
    _stopLoop.value = true;

    // 2) cancele timers ou pause o vídeo
    _imageTimer?.cancel();
    if (videoController?.value.isPlaying ?? false) {
      await videoController!.pause();
    }

    // 3) Atualize dados / recarregue SharedPreferences / etc
    ConfigController configController = Get.find<ConfigController>();
    await configController.refreshData();

    // 4) Resete índice e recarregue lista de mídias
    currentIndex.value = 0;
    await getMidias();

    // 5) Agora, volte a permitir loop e inicie a reprodução de novo
    _stopLoop.value = false;
    if (midias.isNotEmpty) {
      existeMidia.value = true;
      _playMediaNoIndice(currentIndex.value);
    } else {
      existeMidia.value = false;
      isLoading.value = false;
    }

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

  Future<void> _playMediaNoIndice(int idx) async {
    if (_stopLoop.value) return; // se em algum momento pediram para parar, não fazemos nada

    if (midias.isEmpty) {
      existeMidia.value = false;
      isLoading.value = false;
      return;
    }

    // Garantimos que o indice esteja dentro dos limites
    currentIndex.value = idx % midias.length;
    final m = midias[currentIndex.value];
    existeMidia.value = true;

    isLoading.value = true;
    videoReady.value = false;
    print('[playMedia] vai tocar índice ${currentIndex.value}: $m');

    if (m['tipo'] == 'video' && m['file'] != null) {
      // → Tocar vídeo
      // ------------------------------------------------
      if (videoController != null) {
        // Se já existia um controller anterior, descarte-o
        await videoController!.dispose();
        videoController = null;
      }

      videoController = VideoPlayerController.file(File(m['file'] as String))
        ..addListener(_onError);
      await videoController!.initialize();

      isLoading.value = false;
      videoReady.value = true;
      await videoController!.play();
      videoController!.setVolume(1);

      // Agora registramos um listener simples para detectar "término do vídeo"
      videoController!.addListener(() {
        final valor = videoController!.value;
        // Se a posição atual for >= duração e não estiver tocando, é porque acabou
        if (valor.position >= valor.duration && !valor.isPlaying) {
          // Se ainda não foi chamado stopLoop, podemos agendar a próxima mídia
          if (!_stopLoop.value) {
            // Avança índice e chama recursivamente
            final int proximo = (currentIndex.value + 1) % midias.length;
            _playMediaNoIndice(proximo);
          }
        }
      });

    } else {
      // → Mostrar imagem por 20 segundos
      isLoading.value = false;

      // Cancela qualquer timer anterior, só por segurança
      _imageTimer?.cancel();

      // Agenda um Timer para disparar a próxima mídia em 20s
      _imageTimer = Timer(const Duration(seconds: 20), () {
        // Se não foi pedido para parar, avança para próxima
        if (!_stopLoop.value) {
          final int proximo = (currentIndex.value + 1) % midias.length;
          _playMediaNoIndice(proximo);
        }
      });
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