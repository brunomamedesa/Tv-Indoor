import 'package:flutter/material.dart';
import 'package:get/state_manager.dart';
import 'package:tv_indoor/app/controllers/tv_indoor_controller.dart';

class Noticias extends StatelessWidget {
  const Noticias({
    super.key,
    required this.controller,
  });

  final TvIndoorController controller;

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
              style: TextStyle(
                fontSize: 23,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.bold
              ),
            ),
          ],
        );
      } else {
        return Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  controller: controller.scrollController, 
                  itemCount: controller.news.length,
                  itemBuilder: (context, index) {
        
                    final newsItem = controller.news[index];
        
                    return Row(
                      children: [
                        Text(
                          newsItem['texto'] ?? '',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.new_releases_outlined,
                          color: Colors.white,
                          size: 25,
                        ),
                      ],
                    );
        
                  }, 
                ),
              ) 
            )
          ],
        );
      }
    });
  }
}