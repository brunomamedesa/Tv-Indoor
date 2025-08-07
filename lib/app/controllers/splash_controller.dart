import 'dart:async';
import 'package:get/get.dart';
import 'package:tv_indoor/app/controllers/config_controller.dart';
import 'package:tv_indoor/app/utils/globals.dart';

class SplashController extends GetxController {
  
  final RxString statusMessage = 'Inicializando sistema...'.obs;
  final RxBool isLoading = true.obs;
  final RxInt dotOpacity = 0.obs;
  
  Timer? _dotTimer;
  Timer? _messageTimer;
  
  @override
  void onInit() {
    super.onInit();
    _startLoadingAnimation();
    _initializeSystem();
  }
  
  void _startLoadingAnimation() {
    // Animação dos pontos
    _dotTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      dotOpacity.value = (dotOpacity.value + 1) % 4;
    });
    
    // Sequência de mensagens
    _messageTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      switch (timer.tick % 4) {
        case 1:
          statusMessage.value = 'Verificando configurações...';
          break;
        case 2:
          statusMessage.value = 'Conectando ao servidor...';
          break;
        case 3:
          statusMessage.value = 'Carregando recursos...';
          break;
        case 0:
          statusMessage.value = 'Inicializando sistema...';
          break;
      }
    });
  }
  
  Future<void> _initializeSystem() async {
    try {
      // Simular um tempo mínimo de splash para boa experiência
      await Future.delayed(const Duration(seconds: 3));
      
      statusMessage.value = 'Verificando configurações...';
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Verificar se já está configurado
      final configController = Get.put(ConfigController(), permanent: true);
      await configController.autenticarDispositivo();
      
      statusMessage.value = 'Finalizando...';
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Parar animações
      _stopAnimations();
      isLoading.value = false;
      
      // Redirecionar baseado na configuração
      if (configurado.isTrue) {
        statusMessage.value = 'Redirecionando para mídias...';
        await Future.delayed(const Duration(milliseconds: 800));
        Get.offNamed('/tv-indoor');
      } else {
        statusMessage.value = 'Redirecionando para configuração...';
        await Future.delayed(const Duration(milliseconds: 800));
        Get.offNamed('/config');
      }
      
    } catch (e) {
      print('Erro durante inicialização: $e');
      statusMessage.value = 'Erro na inicialização';
      isLoading.value = false;
      
      // Em caso de erro, redireciona para config após 2 segundos
      await Future.delayed(const Duration(seconds: 2));
      Get.offNamed('/config');
    }
  }
  
  void _stopAnimations() {
    _dotTimer?.cancel();
    _messageTimer?.cancel();
  }
  
  @override
  void onClose() {
    _stopAnimations();
    super.onClose();
  }
}
