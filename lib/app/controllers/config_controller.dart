// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:mobile_device_identifier/mobile_device_identifier.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tv_indoor/app/controllers/webview_controller.dart';
import 'package:tv_indoor/app/utils/globals.dart';
import 'package:tv_indoor/app/utils/media_cache_manager.dart';

class ConfigController extends GetxController {
  
  final RxString deviceId = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool loadingMidias = false.obs;
  final RxMap<String, dynamic> deviceData = <String, dynamic>{}.obs;
  final RxList<RxMap<String, dynamic>> midiasCache = <RxMap<String, dynamic>>[].obs;
  


  final baseUrl = kDebugMode ? dotenv.env['BASE_URL_PROD'] : dotenv.env['BASE_URL_PROD'];
  final apiKey = dotenv.env['API_KEY'];

  final dio = Dio();
  final CacheManager _mediaCache = MediaCacheManager();

  double get totalProgress {
    if (midiasCache.isEmpty) return 0.0;
    final sum = midiasCache
        .map((e) => e['progress'] as double)
        .fold(0.0, (a, b) => a + b);
    return sum / midiasCache.length;
  }

  bool get allDone => midiasCache.every((e) => (e['progress'] as double) >= 1.0);



  @override
  Future<void> onInit() async {
    super.onInit();
    deviceId.value = (await getDeviceId())!;
    await autenticarDispositivo();
  }


  Future<String?> getDeviceId() async{
    return await MobileDeviceIdentifier().getDeviceId(); 
  }

  Future<void> fetchData() async {
    try { 
      final response = await dio.get(
        '$baseUrl/dispositivo/${deviceId.value}', 
        options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
        })
      );

      deviceData.value = response.data;

    } on DioException catch (e) {
      print(e);
      rethrow;
    }
  }

  Future<void> autenticarDispositivo() async {
    try {

      isLoading.value = true;
      await fetchData();
      configurado.value = deviceData['configurado']; 

      await saveCotacoes();

      if(configurado.isTrue) {
        
        await handleMidias(deviceData['midias']);
        Get.back();
        print('midiasCache: $midiasCache');

        if(loadingMidias.isFalse){
          Get.offAllNamed('/tv-indoor');
        }
      }
    } catch (e) {
      print(e);
    } finally {
      isLoading.value = false;
    }
    
  }


  Future<void> refreshData() async {
    try {

      isLoading.value = true;
      await fetchData();
      await saveCotacoes();
      await handleMidias(deviceData['midias']);
      Get.back();
      isLoading.value = false;

    } catch (e) {
      print(e);
    }

  }

  Future<void> saveCotacoes() async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      var cotacoes = deviceData['cotacoes'];
      prefs.setString('cotacoes', jsonEncode(cotacoes));
      WebviewController webviewController = Get.find<WebviewController>();
      webviewController.getCotacoes();
  }

  Future<void> handleMidias(List<dynamic> rawMidias) async {
  
    final Set<String> apiUrls = rawMidias
      .map((m) => m['url'] as String)
      .toSet();

    print(apiUrls);

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final items =  prefs.getString('midias');
    final itemsDecoded = jsonDecode(items!) as List;

    final toRemove = itemsDecoded
      .where((m) => !apiUrls.contains(m['url'] as String))
      .toList();  // <— materializa
      
    print('remover: $toRemove');

    for (final rm in toRemove) {
      final url = rm['url'] as String;
      await _mediaCache.removeFile(url);
      itemsDecoded.removeWhere((e) => e['url'] == url);
    }

    prefs.setString('midias', jsonEncode(itemsDecoded));
    showDownloadProgress();
    loadingMidias.value = true;

    final futures = <Future<void>>[];

    for (var m in rawMidias) {
      final url   = m['url']   as String;
      final tipo  = m['tipo']  as String;

      // 1) Cria o RxMap e adiciona na RxList
      final entrada = <String, dynamic>{
        'tipo': tipo,
        'url': url,
        'file': null,
        'progress': 0.0,
      }.obs;

      midiasCache.add(entrada);

      // cria um Completer que vamos completar no evento FileInfo
      final completer = Completer<void>();
      futures.add(completer.future);

      // 2) Pega o stream de download com progresso
      final stream = _mediaCache.getFileStream(url, withProgress: true);

      // 3) Escuta o stream

      stream.listen((resp) {
        if (resp is DownloadProgress) {
          final pct = resp.totalSize != null
              ? resp.downloaded / resp.totalSize!
              : 0.0;
          entrada['progress'] = pct;
          entrada.refresh();

        } else if (resp is FileInfo) 
        {
          entrada['file'] = resp.file.path;
          entrada['progress'] = 1.0;
          entrada.refresh();
          completer.complete();  
                  // sinaliza que esse download acabou
        }
      });
    }

    await Future.wait(futures);
    prefs.setString('midias', jsonEncode(midiasCache));
    loadingMidias.value = false;
    return;

  }

void showDownloadProgress() {
  Get.dialog(
    AlertDialog(
      title: const Text('Baixando mídias'),
      content: SizedBox(
        width: 400,
        height: 50, // espaço suficiente
        child: Obx(() {
          // pega o total agregado
          final pct = totalProgress;
          final label = allDone
            ? 'Concluído!'
            : 'Baixando mídias: ${(pct * 100).toStringAsFixed(0)}%';
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label),
              const SizedBox(height: 16),
              LinearProgressIndicator(value: pct),
            ],
          );
        }),
      ),
    ),
    barrierDismissible: false,
  );
}


}