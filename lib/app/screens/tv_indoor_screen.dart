import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:tv_indoor/app/controllers/tv_indoor_controller.dart';
import 'package:tv_indoor/app/screens/widgets/noticias_widget.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

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

                    key: ValueKey(controller.arquivoAtual['path']),
                    decoration: const BoxDecoration(
                      color: Colors.black,
                    ),
                  child: 
                    controller.arquivoAtual['tipo'] == 'imagem' ?
                      Image.asset(
                        controller.imagemAtual,
                        key: ValueKey(controller.arquivoAtual['path']),
                        fit: BoxFit.fill,
                      )
                    : controller.arquivoAtual['tipo'] == 'video' &&
                                                 controller.videoController!.value.isInitialized ?
                      AspectRatio(
                        key: ValueKey(controller.arquivoAtual['path']),
                        aspectRatio:
                            controller.videoController!
                                .value
                                .aspectRatio,
                        child: VideoPlayer(
                            controller.videoController!,),
                      )
                    : 
                      Container(child: Text('Nao tem nada'),)
                )),
              ),
            ],
          ),

        );
    },);
  }
  
}

