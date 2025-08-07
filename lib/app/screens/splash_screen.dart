import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tv_indoor/app/controllers/splash_controller.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SplashController>();
    
    return Scaffold(
      backgroundColor: const Color.fromRGBO(51, 91, 64, 1.0),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromRGBO(51, 91, 64, 1.0),
              const Color.fromRGBO(34, 61, 43, 1.0),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo principal
              Container(
                width: 300,
                height: 120,
                child: Image.asset(
                  'assets/logos/Logo Rayquimica-1.png',
                  fit: BoxFit.contain,
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Texto de inicialização
              Obx(() => AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  controller.statusMessage.value,
                  key: ValueKey(controller.statusMessage.value),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              )),
              
              const SizedBox(height: 40),
              
              // Indicador de carregamento animado
              Obx(() => controller.isLoading.value
                  ? Column(
                      children: [
                        // Círculo de progresso customizado
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Pontos animados
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (index) =>
                            AnimatedContainer(
                              duration: Duration(milliseconds: 400 + (index * 200)),
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(
                                  controller.dotOpacity.value > index ? 1.0 : 0.3
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
              ),
              
              const SizedBox(height: 80),
              
              // Informações do sistema (discreta)
              Text(
                'TV Indoor System',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Versão 2.0',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
