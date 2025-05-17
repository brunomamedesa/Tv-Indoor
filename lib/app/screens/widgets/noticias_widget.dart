import 'package:flutter/material.dart';
import 'package:get/get_instance/get_instance.dart';
import 'package:get/state_manager.dart';
import 'package:tv_indoor/app/controllers/noticias_controller.dart';
import 'package:intl/intl.dart';


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
                        Row(
                          children: [
                          Text(
                            DateFormat('dd', 'pt_BR').format(DateTime.now()),
                            style: const TextStyle(
                              color:  Color.fromRGBO(13, 137, 73, 1),
                              fontSize: 60,
                              height: 0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          RotatedBox(
                            quarterTurns: 3,
                            child: Text(
                              DateFormat('MMMM', 'pt_BR').format(DateTime.now()),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 20,
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 10, bottom: 23),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: Colors.white
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 135,
                        height: double.infinity,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            StreamBuilder<DateTime>(
                              stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return const SizedBox();
                                                  
                                final time = snapshot.data!;
                                final formattedTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                                                  
                                return Text(
                                  formattedTime,
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 40,      // ajuste a posição vertical
              left: 133,   // ajuste a posição horizontal
              child: Container(
                width: 850,
                height: 70,
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
                      // textAlign: TextAlign.start,
                      style: const TextStyle(
                        color: Color.fromRGBO(66, 97, 76, 1),
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        height: 0
                      ),
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