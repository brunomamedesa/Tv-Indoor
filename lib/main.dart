import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tv_indoor/app/controllers/tv_indoor_controller.dart';
import 'package:tv_indoor/app/screens/tv_indoor_screen.dart';

void main() {

  WidgetsFlutterBinding.ensureInitialized();
  Get.put(TvIndoorController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Tv-Indoor',
      theme: ThemeData(
        primaryColor: const Color(0xFF21A286),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF21A286),
        ),
      ),
      home: TvIndoorScreen(),
    );
  }
}
