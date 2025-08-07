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
import 'package:tv_indoor/app/controllers/noticias_controller.dart';
import 'package:tv_indoor/app/controllers/webview_controller.dart';
import 'package:tv_indoor/app/controllers/sefaz_controller.dart';
import 'package:tv_indoor/app/utils/globals.dart';
import 'package:tv_indoor/app/utils/media_cache_manager.dart';

class ConfigController extends GetxController {
  
  final RxString deviceId = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool loadingMidias = false.obs;
  final RxMap<String, dynamic> deviceData = <String, dynamic>{}.obs;
  final RxList<RxMap<String, dynamic>> midiasCache = <RxMap<String, dynamic>>[].obs;
  final RxString versao = ''.obs;
  
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
    print('🔧 ConfigController inicializando...');
    final id = await getDeviceId();
    deviceId.value = id ?? '';
    print('📱 DeviceId obtido: ${deviceId.value}');
    
    if (deviceId.value.isEmpty) {
      print('❌ ERRO: DeviceId está vazio!');
      return;
    }
    
    await autenticarDispositivo();
  }

  void reset() {
    print('resetando');
    isLoading.value = true;
    deviceId.value = '';
    midiasCache.clear();
    midiasCache.clear();
    onInit();

  }


  Future<String?> getDeviceId() async{
    try {
      final id = await MobileDeviceIdentifier().getDeviceId();
      print('📱 MobileDeviceIdentifier retornou: $id');
      return id;
    } catch (e) {
      print('❌ Erro ao obter deviceId: $e');
      return null;
    }
  }

Future<void> fetchData() async {
  print('📡 Iniciando fetchData para dispositivo: ${deviceId.value}');
  print('🔗 URL: $baseUrl/dispositivo/${deviceId.value}');
  
  try {
    final response = await dio.get(
      '$baseUrl/dispositivo/${deviceId.value}',
      options: Options(
        headers: {'Authorization': 'Bearer $apiKey'},
        // status ≥ 500 não lança exceção ―‐ cuidaremos abaixo
        validateStatus: (code) => code != null && code < 500,
      ),
    );

    print('📡 Response recebido - Status: ${response.statusCode}');

    if (response.statusCode == 200 && response.data != null) {
      deviceData.value = response.data;          // ✅ ok
      
      // LOGS DETALHADOS para debug da API
      print('✅ API Response Status: ${response.statusCode}');
      print('📊 Device Data Keys: ${response.data.keys}');
      
      // Verificar cada campo individualmente
      print('🔧 Dispositivo: ${response.data['dispositivo']}');
      print('💰 Cotações: ${response.data['cotacoes']}');
      print('📰 Notícias: ${response.data['noticias']}');
      print('🌤️ Previsão Tempo: ${response.data['previsao_tempo']}');
      print('🥇 Cotação Metais: ${response.data['cotacao_metais']}');
      print('🎬 Mídias: ${response.data['midias']}');
      
    } else {
      // resposta 404/500 ou corpo nulo
      deviceData.clear();                        // 👈 nada novo
      debugPrint('⚠️ Backend status ${response.statusCode}');
      debugPrint('⚠️ Response body: ${response.data}');
    }
  } on DioException catch (e) {
    // timeout, perda de rede, etc. → só registra, sem rethrow
    debugPrint('❌ Erro de rede detalhado: ${e.message}');
    debugPrint('❌ Tipo do erro: ${e.type}');
    debugPrint('❌ Response: ${e.response?.data}');
    debugPrint('❌ Status Code: ${e.response?.statusCode}');
    deviceData.clear();                          // mantém cache antigo
  } catch (e) {
    debugPrint('❌ Erro não esperado em fetchData: $e');
    deviceData.clear();
  }
}
  Future<void> autenticarDispositivo() async {
    try {
      print('🔐 Iniciando autentificação do dispositivo...');
      print('📱 DeviceId atual: ${deviceId.value}');
      isLoading.value = true;
      
      print('📡 Fazendo fetchData...');
      await fetchData();
      
      if (deviceData.isEmpty) {
        print('❌ DeviceData está vazio após fetchData');
        print('❌ Verifique se o deviceId é válido e se a API está respondendo');
        return;
      }
      
      configurado.value = deviceData['configurado']; 
      print('⚙️ Dispositivo configurado: ${configurado.value}');

      // Salvar status de configuração localmente
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_configured', configurado.value);
      await prefs.setString('device_id', deviceId.value);
      print('💾 Configurações locais salvas');

      print('⏱️ Iniciando timer...');
      iniciaTimer(deviceData['dispositivo']['tempo_atualizacao']);
      
      print('💰 Salvando cotações...');
      await saveCotacoes();
      
      print('📰 Salvando notícias...');
      await saveNoticias();
      
      print('🌤️ Salvando previsão do tempo...');
      await savePrevisaoTempo();
      
      print('🥇 Salvando cotação de metais...');
      await saveCotMetais();
      
      print('🏛️ Atualizando status SEFAZ...');
      await atualizarStatusSefaz();
      
      if(configurado.isTrue) {
        print('🎬 Processando mídias...');
        await handleMidias(deviceData['midias']);
        Get.back();

        if(loadingMidias.isFalse){
          print('🏠 Redirecionando para TV Indoor...');
          Get.offAllNamed('/tv-indoor');
        }
      }
    } catch (e) {
      print('❌ Erro durante autenticação: $e');
    } finally {
      isLoading.value = false;
      print('✅ Autenticação finalizada');
    }
    
  }
  

  Future<void> iniciaTimer(int minutos) async {
    print('print minutos: $minutos');
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('tempo_atualizacao', minutos.toString());
  }

  Future<bool> refreshData() async {
    try {

      isLoading.value = true;
      await fetchData();
      final existeMidiasDiferentes = await verificarMidiasAlteradas();

      configurado.value = deviceData['configurado']; 
      iniciaTimer(deviceData['dispositivo']['tempo_atualizacao']);
      await saveCotacoes();
      await saveNoticias();
      
      // Atualizar status SEFAZ junto com as outras atualizações
      await atualizarStatusSefaz();
      
      if(existeMidiasDiferentes) {
        await handleMidias(deviceData['midias']);
        Get.back();
      }
      isLoading.value = false;
      return existeMidiasDiferentes;

    } catch (e) {
      print(e);
      return false;
    }

  }



  Future<void> saveCotacoes() async {
      print('💰 Iniciando saveCotacoes...');
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      var cotacoes = deviceData['cotacoes'];
      print('💰 Dados das cotações recebidos da API: $cotacoes');
      
      if (cotacoes != null) {
        prefs.setString('cotacoes', jsonEncode(cotacoes));
        print('✅ Cotações salvas no SharedPreferences');
      } else {
        print('❌ Cotações é null - não foi salva');
      }
      
      try {
        WebviewController webviewController = Get.find<WebviewController>();
        webviewController.getCotacoes();
        print('✅ WebviewController.getCotacoes() chamado');
      } catch (e) {
        print('❌ Erro ao chamar WebviewController.getCotacoes(): $e');
      }
  }

  Future<void> savePrevisaoTempo() async {
      print('🌤️ Iniciando savePrevisaoTempo...');
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      var previsao = deviceData['previsao_tempo'];
      print('🌤️ Dados da previsão recebidos da API: $previsao');
      
      if (previsao != null) {
        prefs.setString('previsao_tempo', jsonEncode(previsao));
        print('✅ Previsão salva no SharedPreferences');
      } else {
        print('❌ Previsão é null - não foi salva');
      }
      
      try {
        WebviewController webviewController = Get.find<WebviewController>();
        webviewController.getPrevisao();
        print('✅ WebviewController.getPrevisao() chamado');
      } catch (e) {
        print('❌ Erro ao chamar WebviewController.getPrevisao(): $e');
      }
  }

  Future<void> saveCotMetais() async {
      print('🥇 Iniciando saveCotMetais...');
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      var metais = deviceData['cotacao_metais'];
      print('🥇 Dados dos metais recebidos da API: $metais');
      
      if (metais != null) {
        prefs.setString('cotacao_metais', jsonEncode(metais));
        print('✅ Cotação metais salva no SharedPreferences');
      } else {
        print('❌ Cotação metais é null - não foi salva');
      }
      
      try {
        WebviewController webviewController = Get.find<WebviewController>();
        webviewController.getMetais();
        print('✅ WebviewController.getMetais() chamado');
      } catch (e) {
        print('❌ Erro ao chamar WebviewController.getMetais(): $e');
      }
  }

  Future<void> saveNoticias() async {
      print('📰 Iniciando saveNoticias...');
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      var noticias = deviceData['noticias'];
      print('📰 Dados das notícias recebidos da API: $noticias');
      
      if (noticias != null) {
        prefs.setString('noticias', jsonEncode(noticias));
        print('✅ Notícias salvas no SharedPreferences');
      } else {
        print('❌ Notícias é null - não foi salva');
      }
      
      try {
        // Tentar encontrar ou criar o controller
        NoticiasController noticiasController;
        if (Get.isRegistered<NoticiasController>()) {
          noticiasController = Get.find<NoticiasController>();
          print('✅ NoticiasController encontrado');
        } else {
          noticiasController = Get.put(NoticiasController());
          print('✅ NoticiasController criado');
        }
        
        noticiasController.getNoticias();
        print('✅ NoticiasController.getNoticias() chamado');
      } catch (e) {
        print('❌ Erro ao trabalhar com NoticiasController: $e');
      }
  }

  Future<void> handleMidias(List<dynamic> rawMidias) async {
    // (A) ──────────────────────────────────────────────────────────────
    // 1. Zere a lista em memória para não acumular duplicatas
    midiasCache.clear();

    // 2. Limpe (em disco) arquivos que não estão mais na API ───────────
    // Só remove arquivos de vídeos e imagens, URLs não são armazenadas em cache
    final apiUrls = rawMidias.map((m) => m['url'] as String).toSet();
    final prefs   = await SharedPreferences.getInstance();
    final stored  = prefs.getString('midias');
    if (stored != null) {
      final storedList = jsonDecode(stored) as List;
      final toRemove   = storedList
          .where((m) => !apiUrls.contains(m['url'] as String) && (m['tipo'] == 'video' || m['tipo'] == 'imagem'))
          .toList();

      print(toRemove);
      for (final rm in toRemove) {
        await _mediaCache.removeFile(rm['url'] as String);
      }
    }

    // 3. Mostre o diálogo de progresso antes de começar a baixar ───────
    showDownloadProgress();
    loadingMidias.value = true;

    // (B) ──────────────────────────────────────────────────────────────
    // 4. Baixe as mídias com barra de progresso (apenas vídeos e imagens)
    final downloadFutures = <Future<void>>[];

    for (final m in rawMidias) {
      final entrada = <String, dynamic>{
        'tipo'            : m['tipo'],
        'url'             : m['url'],
        'file'            : null,
        'progress'        : 0.0,
        'qlik_integration': m['qlik_integration'] ?? false,
        'url_externa'     : m['url_externa'],
        'url_original'    : m['url_original'],
      }.obs;
      midiasCache.add(entrada);

      if (m['tipo'] == 'video' || m['tipo'] == 'imagem') {
        // Download apenas para vídeos e imagens
        final c = Completer<void>();
        downloadFutures.add(c.future);

        _mediaCache.getFileStream(m['url'], withProgress: true).listen((resp) {
          if (resp is DownloadProgress) {
            final pct = resp.totalSize != null
                ? resp.downloaded / resp.totalSize!
                : 0.0;
            entrada['progress'] = pct;
            entrada.refresh();
          } else if (resp is FileInfo) {
            entrada['file']     = resp.file.path;
            entrada['progress'] = 1.0;
            entrada.refresh();
            c.complete();
          }
        });
      } else if (m['tipo'] == 'url') {
        // URLs são "baixadas" instantaneamente
        entrada['progress'] = 1.0;
        entrada['file'] = m['url']; // Para URLs, o "file" é a própria URL
        entrada.refresh();
      }
    }

    await Future.wait(downloadFutures);

    // (C) ──────────────────────────────────────────────────────────────
    // 5. Gere lista "limpa" (sem progress, sem Rx) p/ gravar no prefs
    final listaParaPrefs = [
      for (final rx in midiasCache)
        {
          'tipo'            : rx['tipo'],
          'url'             : rx['url'],
          'file'            : rx['file'],
          'qlik_integration': rx['qlik_integration'] ?? false,
          'url_externa'     : rx['url_externa'],
          'url_original'    : rx['url_original'],
        }
    ];
    await prefs.setString('midias', jsonEncode(listaParaPrefs));

    // 6. Feche diálogo e sinalize fim
    loadingMidias.value = false;
    Get.back();                       // fecha o AlertDialog de download
  }

  // Future<void> handleMidias(List<dynamic> rawMidias) async {

  //   midiasCache.clear();
  //   final Set<String> apiUrls = rawMidias
  //     .map((m) => m['url'] as String)
  //     .toSet();

  //   final SharedPreferences prefs = await SharedPreferences.getInstance();

  //   final items =  prefs.getString('midias');
  //   if(items != null) {
  //     final itemsDecoded = jsonDecode(items) as List;
    
  //     final toRemove = itemsDecoded
  //       .where((m) => !apiUrls.contains(m['url'] as String))
  //       .toList();  // <— materializa
        
  //     print('remover: $toRemove');

  //     for (final rm in toRemove) {
  //       final url = rm['url'] as String;
  //       await _mediaCache.removeFile(url);
  //       itemsDecoded.removeWhere((e) => e['url'] == url);
  //     }

  //     prefs.setString('midias', jsonEncode(itemsDecoded));
  //     showDownloadProgress();
  //   }
    
  //   loadingMidias.value = true;

  //   final futures = <Future<void>>[];

  //   for (var m in rawMidias) {
  //     final url   = m['url']   as String;
  //     final tipo  = m['tipo']  as String;

  //     // 1) Cria o RxMap e adiciona na RxList
  //     final entrada = <String, dynamic>{
  //       'tipo': tipo,
  //       'url': url,
  //       'file': null,
  //       'progress': 0.0,
  //     }.obs;

  //     midiasCache.add(entrada);

  //     // cria um Completer que vamos completar no evento FileInfo
  //     final completer = Completer<void>();
  //     futures.add(completer.future);

  //     // 2) Pega o stream de download com progresso
  //     final stream = _mediaCache.getFileStream(url, withProgress: true);

  //     // 3) Escuta o stream

  //     stream.listen((resp) {
  //       if (resp is DownloadProgress) {
  //         final pct = resp.totalSize != null
  //             ? resp.downloaded / resp.totalSize!
  //             : 0.0;
  //         entrada['progress'] = pct;
  //         entrada.refresh();

  //       } else if (resp is FileInfo) 
  //       {
  //         entrada['file'] = resp.file.path;
  //         entrada['progress'] = 1.0;
  //         entrada.refresh();
  //         completer.complete();  
  //                 // sinaliza que esse download acabou
  //       }
  //     });
  //   }

  //   await Future.wait(futures);
  //   prefs.setString('midias', jsonEncode(midiasCache));
  //   loadingMidias.value = false;
  //   return;

  // }

  //SEMPRE QUE CHAMAR, CERTIFICAR DE CHAMAR FETCH DATA ANTES
  Future<bool> verificarMidiasAlteradas() async {

    // 2) Extrai lista de URLs da API
    final List<dynamic> apiMidias = deviceData['midias'] as List<dynamic>;
    final Set<String> apiUrls = apiMidias
        .map((m) => m['url'] as String)
        .toSet();

    // 3) Busca o JSON armazenado em SharedPreferences
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? storedJson = prefs.getString('midias');

    // Se não houver nada armazenado, considera alteração se a API retornar alguma mídia
    if (storedJson == null) {
      return apiUrls.isNotEmpty;
    }

    // 4) Decodifica o JSON salvo e extrai as URLs
    final List<dynamic> storedList = jsonDecode(storedJson) as List<dynamic>;
    final Set<String> storedUrls = storedList
        .map((m) => (m as Map<String, dynamic>)['url'] as String)
        .toSet();

    // 5) Compara os dois conjuntos de URLs
    // setEquals vem de 'package:flutter/foundation.dart'
    return !setEquals(apiUrls, storedUrls);
  }

  // Método para buscar URL do Qlik com ticket
  Future<String?> getQlikUrl(String qlikApiUrl) async {
    try {
      final response = await dio.get(
        qlikApiUrl,
        options: Options(
          headers: {'Authorization': 'Bearer $apiKey'},
          validateStatus: (code) => code != null && code < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['success'] == true && data['ready_to_use'] == true) {
          return data['qlik_url'] as String?;
        }
      }
      return null;
    } on DioException catch (e) {
      debugPrint('⚠️ Erro ao buscar URL do Qlik: $e');
      return null;
    }
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

  Future<void> atualizarStatusSefaz() async {
    try {
      // Tentar encontrar ou criar o SefazController
      SefazController sefazController;
      if (Get.isRegistered<SefazController>()) {
        sefazController = Get.find<SefazController>();
        print('✅ SefazController encontrado');
      } else {
        sefazController = Get.put(SefazController());
        print('✅ SefazController criado');
      }
      
      await sefazController.atualizarAgora();
      print('✅ Status SEFAZ atualizado');
    } catch (e) {
      print('❌ Erro ao atualizar status SEFAZ: $e');
    }
  }

}