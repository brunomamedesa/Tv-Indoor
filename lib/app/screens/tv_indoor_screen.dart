import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tv_indoor/app/controllers/config_controller.dart';
import 'package:tv_indoor/app/controllers/tv_indoor_controller.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

class TvIndoorScreen extends StatelessWidget {

  TvIndoorScreen({super.key});
  final TvIndoorController controller = Get.find();
  
  @override
  Widget build(BuildContext context) {
    return 
    Obx(() {
      print('midia atual wiget: ${controller.mediaAtual}');
      return 
        Scaffold(
          backgroundColor: Colors.white,
          body: 
          Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: AnimatedSwitcher(
                  duration: const Duration(seconds: 1),
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,

                    key: ValueKey(controller.mediaAtual['file']),
                    decoration: const BoxDecoration(
                      color: Colors.black,
                    ),
                  child: Column(
                    children: [
                      if (controller.isLoading.isTrue) ... [
                        const Expanded(child:  Center(child: CircularProgressIndicator(),))
                      ] else if (controller.existeMidia.isTrue && controller.mediaAtual['tipo'] == 'video' && controller.videoController!.value.isInitialized) ... [
                        
                        Expanded(
                          child: AspectRatio(
                            key: ValueKey(controller.mediaAtual['file']),
                            aspectRatio:
                                controller.videoController!
                                    .value
                                    .aspectRatio,
                            child: VideoPlayer(
                                controller.videoController!,),
                          ),
                        )
                      ] else if (controller.existeMidia.isTrue &&  controller.mediaAtual['tipo'] == 'imagem') ... [
                        Expanded(
                          child: Container(
                            key: ValueKey(controller.mediaAtual['file']),
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: FileImage(File(controller.mediaAtual['file'])),
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
                        )
                      ]
                    ],
                  )

                    
                    
                )),
              ),
              Positioned(
                right: 3,
                top: 3,
                child: Image.asset(
                  'assets/logos/logoTV01.png',
                  height: 50,
                )
              )
            ],
          ),

        );
    },);
  }
  
}

