import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:tv_indoor/app/controllers/config_controller.dart';
import 'package:tv_indoor/app/controllers/tv_indoor_controller.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

import 'package:webview_flutter/webview_flutter.dart';
import 'package:tv_indoor/app/screens/widgets/simple_noticias_widget.dart';

class TvIndoorScreen extends StatelessWidget {

  TvIndoorScreen({super.key});
  final TvIndoorController controller = Get.find();
  
  @override
  Widget build(BuildContext context) {
    return 
    Obx(() {      
      return 
        Scaffold(
          backgroundColor: Colors.white,
          body: 
          Column(
            children: [
              // Header verde quando for WebView - ALTURA AUMENTADA
              if (controller.isWebview.isTrue) 
                Container(
                  width: double.infinity,
                  height: 80, // Aumentei de 50 para 80px
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.fromRGBO(51, 91, 64, 1.0),
                        Color.fromRGBO(41, 71, 54, 1.0),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Primeira linha - ícone e título
                        Row(
                          children: [
                            const Icon(
                              Icons.language,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Conteúdo Web',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            // Indicador de carregamento ou status
                            Obx(() => controller.webviewLoaded.value 
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 22,
                                )
                              : Container(
                                  width: 22,
                                  height: 22,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Segunda linha - informações adicionais
                        Row(
                          children: [
                            const Icon(
                              Icons.dashboard,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Dashboard Interativo',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Obx(() => Text(
                              controller.webviewLoaded.value ? 'Carregado' : 'Carregando...',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            )),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              // Área principal das mídias
              Expanded(
                child: Stack(
                  children: [
                    // Conteúdo principal (WebView ou mídias)
                    controller.isWebview.isTrue
                        ? 
                        // WebView ocupando 100% da área disponível - SEM fundo cinza
                        WebViewWidget(
                          controller: controller.webview,
                        )
                        :
                        // Para outros tipos de mídia
                        SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: AnimatedSwitcher(
                            duration: const Duration(seconds: 1),
                            child: Container(
                              width: MediaQuery.of(context).size.width,
                              height: MediaQuery.of(context).size.height,
                              key: ValueKey(controller.midias.isNotEmpty ? controller.midias[controller.currentIndex.value]['file'] : ''),
                              decoration: const BoxDecoration(
                                color: Colors.black,
                              ),
                              child: Column(
                                children: [
                                  if (controller.isLoading.isTrue) ... [
                                    const Expanded(
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3,
                                        ),
                                      ),
                                    ),
                                  ] else if (controller.existeMidia.isTrue &&
                                       controller.midias[controller.currentIndex.value]['tipo'] == 'video' &&
                                       controller.videoReady.isTrue &&
                                       controller.videoController != null &&
                                       controller.videoController!.value.isInitialized) ... [
                                    Expanded(
                                      child: AspectRatio(
                                        key: ValueKey(controller.midias.isNotEmpty ? controller.midias[controller.currentIndex.value]['file'] : ''),
                                        aspectRatio:
                                            controller.videoController!
                                                .value
                                                .aspectRatio,
                                        child: VideoPlayer(
                                            controller.videoController!,),
                                      ),
                                    )
                                  ] else if (controller.existeMidia.isTrue &&  controller.midias[controller.currentIndex.value]['tipo'] == 'imagem') ... [
                                    Expanded(
                                      child: Container(
                                        key: ValueKey(controller.midias.isNotEmpty ? controller.midias[controller.currentIndex.value]['file'] : ''),
                                        width: double.infinity, 
                                        height: double.infinity,
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            image: FileImage(File(controller.midias[controller.currentIndex.value]['file'])),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ] else if (controller.existeMidia.isFalse && controller.isLoading.isFalse) ... [
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Center(
                                            child: Text(
                                              'Mídias Indisponíveis.',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 20
                                              ),
                                            ),
                                          ),
                                          const Center(
                                            child: Text(
                                              'É necessário realizar o cadastro das mídias no sistema.',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 20,),
                                          Center(
                                            child: ElevatedButton(
                                              onPressed:() {
                                                final ConfigController config = Get.find<ConfigController>();
                                                config.refreshData();
                                                controller.reload();

                                              }, 
                                              autofocus: true,
                                              style: ElevatedButton.styleFrom(
                                                shape: const RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.all(Radius.circular(5))
                                                ),
                                                backgroundColor: const Color.fromRGBO(51, 91, 64, 1.0),
                                                elevation: 3,

                                              ).copyWith(
                                                overlayColor: WidgetStateProperty.resolveWith<Color?>(
                                                  (states) {
                                                    if (states.contains(WidgetState.focused)) {
                                                      return Colors.green.shade500; // cor de foco
                                                    }
                                                    // você também pode tratar hovered, pressed, etc:
                                                    // if (states.contains(MaterialState.hovered)) return Colors.blue.withOpacity(0.2);
                                                    return null; // empurra p/ padrão para outros estados
                                                  },
                                                ),
                                              ),
                                              child: const Text(
                                                'Atualizar',
                                                style: TextStyle(
                                                  color: Colors.white
                                                ),
                                              )
                                            ),
                                          )
                                        ],
                                      )
                                    ),
                                  ] else if (controller.erroVideo.value.isNotEmpty) ... [
                                    // Mostrar erro de vídeo
                                    Expanded(
                                      child: Container(
                                        color: Colors.red.withOpacity(0.1),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.error_outline,
                                              color: Colors.red,
                                              size: 64,
                                            ),
                                            const SizedBox(height: 16),
                                            const Text(
                                              'Erro na Reprodução de Vídeo',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              controller.erroVideo.value,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 14,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            if (controller.midias.isNotEmpty) ...[
                                              const SizedBox(height: 16),
                                              Text(
                                                'Arquivo: ${controller.midias[controller.currentIndex.value]['file']}',
                                                style: const TextStyle(
                                                  color: Colors.white60,
                                                  fontSize: 12,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    // Estado padrão quando não há mídia
                                    const Expanded(
                                      child: Center(
                                        child: Text(
                                          'Nenhuma mídia disponível',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ]
                              ),
                            ),
                          ),
                        ),
                    // Logo pequena posicionada no canto superior direito (como estava antes)
                    if (!controller.isWebview.isTrue) // Só mostra quando não é WebView
                      Positioned(
                        right: 3,
                        top: 3,
                        child: Image.asset(
                          'assets/logos/logoTV01.png',
                          height: 50,
                        ),
                      ),
                  ],
                ),
              ),
              // Barra fixa de notícias na parte inferior
              SimpleNoticias(),
            ],
          ),

        );
    },);
  }
  
}
