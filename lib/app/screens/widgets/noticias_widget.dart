import 'package:flutter/material.dart';
import 'package:get/get_instance/get_instance.dart';
import 'package:get/state_manager.dart';
import 'package:tv_indoor/app/controllers/noticias_controller.dart';


class Noticias extends StatelessWidget {
  Noticias({
    super.key,
  });

  final controller = Get.put(NoticiasController());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if(controller.news.isEmpty){
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Carregando Notícias${controller.loadingDots}',
              style: const TextStyle(
                fontSize: 23,
                color: Colors.white,
                fontWeight: FontWeight.bold
              ),
            ),
          ],
        );
      } else {
        return 
        Stack(
          children: [
            Column(
              children: [
                Container(
                  color: const Color.fromARGB(255, 15, 26, 18),
                  width: double.infinity,
                  height: 70,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 15),
                    child: Row(
                      children: [
                        Container(
                          height: 20,
                          width: 150,
                          decoration: const BoxDecoration(
                            color: Color.fromRGBO(17, 137, 73, 1)
                          ),
                          child: Center(
                            child: Text(
                              controller.news[controller.currentIndex.value]['tag'],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Colors.white
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(), // Espaço vazio onde estava o relógio
                ),
              ],
            ),
            Positioned(
              top: 30,      // ajuste a posição vertical
              left: 15,     // ajuste a posição horizontal para começar mais à esquerda
              child: Container(
                width: 970,   // aumentada a largura para ocupar mais espaço
                height: 80,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child:  Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      controller.news[controller.currentIndex.value]['titulo'],
                      style: const TextStyle(
                        color: Color.fromRGBO(66, 97, 76, 1),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 0
                      ),
                      softWrap: false,
                    ),
                    Text(
                      controller.news[controller.currentIndex.value]['noticia'],
                      softWrap: true,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        height: 0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }
    });
  }
}