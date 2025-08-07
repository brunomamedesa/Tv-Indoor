import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SefazController extends GetxController {
  final RxMap<String, String> servicos = <String, String>{}.obs;
  final RxBool isLoading = false.obs;
  final RxString ultimaAtualizacao = ''.obs;
  final RxString statusGeral = 'carregando'.obs;

  final dio = Dio();
  Timer? _timer;
  
  final baseUrl = 'https://rayquimica.bstechsolutions.com/api/sefaz-go';
  final apiKey = dotenv.env['API_KEY'];

  // Mapa para traduzir os nomes dos serviços
  final Map<String, String> servicosNomes = {
    'nfe_autorizacao_4_00': 'NFe - Autorização',
    'nfe_ret_autorizacao_4_00': 'NFe - Retorno Autorização',
    'nfe_consulta_protocolo_4_00': 'NFe - Consulta Protocolo',
    'nfe_status_servico_4_00': 'NFe - Status Serviço',
    'nfe_consulta_cadastro_4_00': 'NFe - Consulta Cadastro',
    'nfe_recepcao_evento_4_00': 'NFe - Recepção Evento',
    'nfe_inutilizacao_4_00': 'NFe - Inutilização',
    'nfe_distribuicao_dfe': 'NFe - Distribuição DFe',
  };

  @override
  void onInit() {
    super.onInit();
    print('🏛️ SefazController inicializando...');
    _carregarDadosCache();
    _buscarStatusSefaz();
    _iniciarTimerAtualizacao();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  void _iniciarTimerAtualizacao() {
    // Atualizar a cada 10 minutos
    _timer = Timer.periodic(const Duration(minutes: 10), (timer) {
      print('🕙 Timer SEFAZ: Atualizando dados...');
      _buscarStatusSefaz();
    });
  }

  Future<void> _carregarDadosCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dadosSalvos = prefs.getString('sefaz_status');
      final ultimaAtualizacaoSalva = prefs.getString('sefaz_ultima_atualizacao');
      
      if (dadosSalvos != null) {
        final dados = jsonDecode(dadosSalvos) as Map<String, dynamic>;
        servicos.value = Map<String, String>.from(dados);
        ultimaAtualizacao.value = ultimaAtualizacaoSalva ?? '';
        _atualizarStatusGeral();
        print('🏛️ Dados SEFAZ carregados do cache');
      }
    } catch (e) {
      print('❌ Erro ao carregar dados SEFAZ do cache: $e');
    }
  }

  Future<void> _buscarStatusSefaz() async {
    try {
      print('🏛️ Buscando status SEFAZ-GO...');
      isLoading.value = true;

      final response = await dio.get(
        '$baseUrl/disponibilidade-servicos',
        queryParameters: {'uf': 'GO'},
        options: Options(
          headers: {'Authorization': 'Bearer $apiKey'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final dadosGO = response.data['data']['servicos_por_uf']['GO'];
        final Map<String, String> novosServicos = {};
        
        // Extrair apenas os serviços NFe que queremos monitorar
        for (final chave in servicosNomes.keys) {
          if (dadosGO[chave] != null) {
            novosServicos[chave] = dadosGO[chave].toString();
          }
        }

        servicos.value = novosServicos;
        ultimaAtualizacao.value = DateTime.now().toIso8601String();
        _atualizarStatusGeral();
        
        // Salvar no cache
        await _salvarNoCache();
        
        print('✅ Status SEFAZ atualizado com sucesso');
        print('📊 Serviços: ${servicos.length} monitorados');
        
      } else {
        print('⚠️ API SEFAZ retornou erro: ${response.statusCode}');
        print('📄 Response: ${response.data}');
      }
      
    } catch (e) {
      print('❌ Erro ao buscar status SEFAZ: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _atualizarStatusGeral() {
    final valores = servicos.values.toList();
    
    if (valores.isEmpty) {
      statusGeral.value = 'carregando';
      return;
    }

    final servicosOnline = valores.where((s) => s == 'online').length;
    final servicosProblema = valores.where((s) => s == 'problema').length;
    final servicosOffline = valores.where((s) => s == 'offline').length;

    if (servicosOffline > 0) {
      statusGeral.value = 'offline';
    } else if (servicosProblema > 0) {
      statusGeral.value = 'problema';
    } else if (servicosOnline == valores.length) {
      statusGeral.value = 'online';
    } else {
      statusGeral.value = 'parcial';
    }
  }

  Future<void> _salvarNoCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sefaz_status', jsonEncode(servicos));
      await prefs.setString('sefaz_ultima_atualizacao', ultimaAtualizacao.value);
      print('💾 Status SEFAZ salvo no cache');
    } catch (e) {
      print('❌ Erro ao salvar SEFAZ no cache: $e');
    }
  }

  // Método público para forçar atualização
  Future<void> atualizarAgora() async {
    print('🔄 Forçando atualização SEFAZ...');
    await _buscarStatusSefaz();
  }

  // Getter para facilitar o acesso aos dados formatados
  Map<String, Map<String, String>> get servicosFormatados {
    final Map<String, Map<String, String>> resultado = {};
    
    for (final entrada in servicos.entries) {
      resultado[entrada.key] = {
        'nome': servicosNomes[entrada.key] ?? entrada.key,
        'status': entrada.value,
      };
    }
    
    return resultado;
  }

  // Contador de serviços por status
  Map<String, int> get contadores {
    final valores = servicos.values.toList();
    
    return {
      'online': valores.where((s) => s == 'online').length,
      'problema': valores.where((s) => s == 'problema').length,
      'offline': valores.where((s) => s == 'offline').length,
      'total': valores.length,
    };
  }
}
