import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tv_indoor/app/controllers/tv_indoor_controller.dart';
import 'package:tv_indoor/app/screens/tv_indoor_screen.dart';
import 'package:tv_indoor/app/screens/widgets/noticias_widget.dart';
import 'package:tv_indoor/app/screens/widgets/sidebar_widget.dart';

void main() {

  WidgetsFlutterBinding.ensureInitialized();
  Get.put(TvIndoorController());
  runApp( MyApp());
}

class MyApp extends StatelessWidget {
  
  MyApp({super.key});
  final controller = Get.find<TvIndoorController>();

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Tv-Indoor',
      home:  Scaffold(
        backgroundColor: Colors.transparent,
        body: Row(
          children: [
            Padding(
              padding:  const EdgeInsets.only(left: 8),
              child: SideBar(),
            ),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    flex: 5,
                    child: TvIndoorScreen()
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      color: const Color.fromRGBO(51, 91, 64, 1.0),
                      child: Noticias(controller: controller)
                    )
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
