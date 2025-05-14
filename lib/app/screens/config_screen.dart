
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tv_indoor/app/controllers/config_controller.dart';
import 'package:tv_indoor/app/utils/globals.dart';

class ConfigScreen extends StatelessWidget {

  ConfigScreen({super.key});
  final ConfigController controller = Get.find();
  
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // const SideBar(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                      
                    )
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Text(
                              'Contate o suporte para concluir a configuração do dispositivo.',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800
                              ),
                              softWrap: true,
                            ),
                          ),
                          const SizedBox(height: 20,),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Id do dispositivo: ',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800
                                                      
                                  ),
                                ),
                                Text(
                                  controller.deviceId.value,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black
                            
                                  ),
                                ),
                                const SizedBox(height: 20,),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width / 3,
                                  height: 60,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      await controller.autenticarDispositivo();
                                      if(controller.allDone && configurado.isTrue){
                                          Get.offNamed('/tv-indoor');
                                      }
                                    },
                                    autofocus: true, // para TVs, assegure que o botão receba foco
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStateProperty.all(Colors.blue.shade100),
                                      shape: WidgetStateProperty.all<OutlinedBorder>(
                                        RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15), // ajuste o valor conforme desejado
                                        ),
                                      ),
                                      overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
                                        if (states.contains(WidgetState.pressed)) {
                                          // Se pressed, retorna azul claro com 50% de opacidade
                                          return Colors.blue.shade900;
                                        } else if (states.contains(WidgetState.focused)) {
                                          // Se focado, destaque em laranja
                                          return Colors.blue;
                                        }
                                        return null; // retorna o valor padrão caso não esteja em nenhum estado especial
                                      }),
                                    ),
                                    child: const Text(
                                      'Configuração finalizada!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        )
      );
    });
  }
}