import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tv_indoor/app/controllers/noticias_controller.dart';

class SimpleNoticias extends StatelessWidget {
  SimpleNoticias({super.key});

  final controller = Get.put(NoticiasController());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.news.isEmpty) {
        return const SizedBox.shrink(); // Não mostra nada se não há notícias
      }

      return Container(
        width: double.infinity,
        height: 80, // Altura fixa da barra de notícias
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromRGBO(51, 91, 64, 1.0), // Verde principal da empresa
              Color.fromRGBO(41, 71, 54, 1.0), // Verde mais escuro
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, -2),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          children: [
            // Ícone de notícias
            Container(
              width: 60,
              height: double.infinity,
              decoration: const BoxDecoration(
                color: Color.fromRGBO(41, 71, 54, 0.8),
              ),
              child: const Icon(
                Icons.newspaper,
                color: Colors.white,
                size: 28,
              ),
            ),
            // Divisor
            Container(
              width: 1,
              height: double.infinity,
              color: Colors.white.withOpacity(0.3),
            ),
            // Conteúdo das notícias
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Tag da notícia
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        controller.news[controller.currentIndex.value]['tag'] ?? 'NOTÍCIA',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Conteúdo da notícia
                    Expanded(
                      child: Text(
                        controller.news[controller.currentIndex.value]['noticia'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Indicador de progresso
            Container(
              width: 40,
              height: double.infinity,
              decoration: const BoxDecoration(
                color: Color.fromRGBO(41, 71, 54, 0.8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${controller.currentIndex.value + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${controller.qtdNoticias.value}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Barra de progresso
                  Container(
                    width: 20,
                    height: 2,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(1),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (controller.currentIndex.value + 1) / controller.qtdNoticias.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
