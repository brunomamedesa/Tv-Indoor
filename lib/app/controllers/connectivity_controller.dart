import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class ConnectivityController extends GetxController {
  final RxBool isConnected = true.obs;
  final RxString connectionType = 'wifi'.obs;
  
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  final Connectivity _connectivity = Connectivity();

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _initConnectivity() async {
    try {
      final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      print('Erro ao verificar conectividade inicial: $e');
      isConnected.value = false;
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) async {
    print('🔍 Verificando conectividade: $results');
    
    if (results.contains(ConnectivityResult.none)) {
      print('❌ Sem conectividade detectada');
      isConnected.value = false;
      connectionType.value = 'none';
    } else {
      // Primeiro, define o tipo de conexão
      if (results.contains(ConnectivityResult.wifi)) {
        connectionType.value = 'wifi';
      } else if (results.contains(ConnectivityResult.ethernet)) {
        connectionType.value = 'ethernet';
      } else if (results.contains(ConnectivityResult.mobile)) {
        connectionType.value = 'mobile';
      } else {
        connectionType.value = 'other';
      }
      
      print('📡 Tipo de conexão: ${connectionType.value}');
      
      // Depois verifica se realmente tem acesso à internet
      bool hasInternet = await _checkInternetAccess();
      isConnected.value = hasInternet;
      
      print('🌐 Acesso à internet: ${hasInternet ? "SIM" : "NÃO"}');
    }
  }

  Future<bool> _checkInternetAccess() async {
    try {
      print('🔍 Testando acesso à internet...');
      
      // Testar múltiplos endereços para maior confiabilidade
      final hosts = ['8.8.8.8', 'cloudflare.com', 'google.com'];
      
      for (final host in hosts) {
        try {
          final result = await InternetAddress.lookup(host).timeout(
            const Duration(seconds: 3),
          );
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            print('✅ Conectividade confirmada via $host');
            return true;
          }
        } catch (e) {
          print('⚠️ Falha ao conectar com $host: $e');
          continue;
        }
      }
      
      print('❌ Todos os testes de conectividade falharam');
      return false;
    } catch (e) {
      print('❌ Erro geral no teste de conectividade: $e');
      return false;
    }
  }

  @override
  void onClose() {
    _connectivitySubscription.cancel();
    super.onClose();
  }
}
