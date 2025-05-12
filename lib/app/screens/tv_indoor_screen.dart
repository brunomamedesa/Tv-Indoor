import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
      final m = controller.mediaAtual;
      print(m);
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

                    key: ValueKey(m['file']),
                    decoration: const BoxDecoration(
                      color: Colors.black,
                    ),
                  child: 
                    m.isEmpty ?
                      const Center(child: CircularProgressIndicator(),)
                      :
                    m['url'].toString().endsWith('.mp4') && controller.videoController!.value.isInitialized == true ?
                      AspectRatio(
                        key: ValueKey(m['file']),
                        aspectRatio:
                            controller.videoController!
                                .value
                                .aspectRatio,
                        child: VideoPlayer(
                            controller.videoController!,),
                      )
                    : !m['url'].toString().endsWith('.mp4') ?
                      Image.file(
                        File(m['file']),
                        key: ValueKey(m['file']),
                        fit: BoxFit.fill,
                      )
                    : 
                    const Center(child: CircularProgressIndicator(),)
                )),
              ),
            ],
          ),

        );
    },);
  }
  
}

