
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

    // ── 1. Checa rapidamente se há mídias novas ─────────────────────────
    final cfg = Get.find<ConfigController>();
    await cfg.fetchData();  
    if (cfg.deviceData.isEmpty) {
      getTempoAtualizacao();
      isLoading.value = false;
      return;
    }
                           // GET leve
    final bool midiasMudaram = await cfg.verificarMidiasAlteradas();
    await cfg.saveCotacoes();
    await cfg.saveNoticias();
    await cfg.savePrevisaoTempo();
    await cfg.saveCotMetais();

    // ── 2A. NÃO mudou nada  →  simplesmente continua ────────────────────
    if (!midiasMudaram) {
      // Se, por acaso, um vídeo estava pausado, retomamos
      if (videoController?.value.isInitialized == true &&
          !videoController!.value.isPlaying) {
        await videoController!.play();
      }
      getTempoAtualizacao();   // agenda próximo reload
      isLoading.value = false;
      return;                  // sai sem mexer em timers ou índices
    }
    // ── 2B. MUDOU → precisamos atualizar ────────────────────────────────
    _stopLoop.value = true;          // bloqueia callbacks de imagem/vídeo
    _imageTimer?.cancel();           // cancela timer de imagem, se houver
    _imageTimer = null;

    if (videoController != null) {
      await videoController!.pause();     // pausa o vídeo atual
      await videoController!.dispose();   // descarta controller + listeners
      videoController = null;
      videoReady.value = false;
    }

    // ── 3. Baixa e grava novas mídias (mostra o diálogo de progresso) ───
    await cfg.handleMidias(cfg.deviceData['midias']);   // aguarda download

    // ── 4. Recarrega lista salva no SharedPreferences ───────────────────
    await getMidias();
    currentIndex.value = 0;

    // ── 5. Libera o loop e começa do índice 0 ───────────────────────────
    _stopLoop.value = false;
    if (midias.isNotEmpty) {
      existeMidia.value = true;
      _playMediaNoIndice(0);
    } else {
      existeMidia.value = false;
      isLoading.value = false;
    }

    getTempoAtualizacao();   // agenda próximo reload
    isLoading.value = false;
  }


  Future<void> getMidias() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('midias');
    if (json == null) {
      midias.clear();
      return;
    }
    midias.assignAll(
      (jsonDecode(json) as List)
          .map((e) => Map<String, dynamic>.from(e).obs)
          .toList(),
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
      await Future.delayed(videoController!.value.duration);

      if (!_stopLoop.value) {
        final int proximo = (currentIndex.value + 1) % midias.length;
        _playMediaNoIndice(proximo);
      }


    } else {
      // → Mostrar imagem por 20 segundos
      isLoading.value = false;
      await Future.delayed(const Duration(seconds: 20));
      if (!_stopLoop.value) {
        final int proximo = (currentIndex.value + 1) % midias.length;
        _playMediaNoIndice(proximo);
      }

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