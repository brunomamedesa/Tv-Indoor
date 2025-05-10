import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tv_indoor/app/controllers/tv_indoor_controller.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SideBar extends StatelessWidget {

  final TvIndoorController controller = Get.find();
  SideBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.none,
      width: 240,
      height: double.infinity,
      decoration: const BoxDecoration(
        // borderRadius: BorderRadiusDirectional.only(),
        color:  Color.fromRGBO(51, 91, 64, 1.0),
      ),
      child: 
          Column(   
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Row(
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 12, top: 8, ),
                        child: Text(
                          'TV',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 50,
                            height: 0
                          ),
                        )
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 10, top: 15),
                        child: Text(
                          'indoor',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 35,
                            height: 0
                          ),
                        )
                      ),
                    ],
                  ),
                  Transform.translate(
                    offset: const Offset(14, -10), // x = 12 para alinhar o left, y = -6 para subir
                    child: const Text(
                      'tv corporativa',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w100,
                        fontSize: 15,
                        height: 1.0,
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 50,),
              SizedBox(
                height: 95,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: WebViewWidget(controller: controller.webview),
                ),
              ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Container(child: Text('Teste'),),
                ),
              ),
            ],
          )
      );
  }
}