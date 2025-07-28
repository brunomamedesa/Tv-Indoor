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
    if (results.contains(ConnectivityResult.none)) {
      isConnected.value = false;
      connectionType.value = 'none';
    } else {
      // Verifica se realmente tem acesso à internet
      bool hasInternet = await _checkInternetAccess();
      isConnected.value = hasInternet;
      
      if (results.contains(ConnectivityResult.wifi)) {
        connectionType.value = 'wifi';
      } else if (results.contains(ConnectivityResult.ethernet)) {
        connectionType.value = 'ethernet';
      } else if (results.contains(ConnectivityResult.mobile)) {
        connectionType.value = 'mobile';
      } else {
        connectionType.value = 'other';
      }
    }
  }

  Future<bool> _checkInternetAccess() async {
    try {
      final result = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 5),
      );
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  void onClose() {
    _connectivitySubscription.cancel();
    super.onClose();
  }
}
