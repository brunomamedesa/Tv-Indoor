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
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'TV'
                    )
                  ),
                ],
              ),
              Expanded(
                flex: 2,
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
              // Padding(
              //   padding: const EdgeInsets.only(bottom: 10),
              //   child: Center(
              //     child: StreamBuilder<DateTime>(
              //       stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
              //       builder: (context, snapshot) {
              //         if (!snapshot.hasData) return const SizedBox();
                
              //         final time = snapshot.data!;
              //         final formattedTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
                
              //         return Text(
              //           formattedTime,
              //           style: const TextStyle(
              //             fontSize: 20,
              //             fontWeight: FontWeight.bold,
              //             color: Colors.white,
              //           ),
              //         );
              //       },
              //     ),
              //   ),
              // )
            ],
          )
      );
  }
}