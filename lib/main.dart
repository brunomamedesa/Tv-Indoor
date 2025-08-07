import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tv_indoor/app/routes/app_pages.dart';
import 'package:tv_indoor/app/screens/widgets/sidebar_widget.dart';
import 'package:tv_indoor/app/controllers/connectivity_controller.dart';
import 'package:tv_indoor/app/controllers/sefaz_controller.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';          // ← import dotenv

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  initializeDateFormatting('pt_BR');

  // Inicializar controller de conectividade
  Get.put(ConnectivityController());
  
  // Inicializar SefazController globalmente
  Get.put(SefazController(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tv-Indoor',
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Row(
            children: [
              Padding(
                padding:  const EdgeInsets.only(left: 8),
                child: SideBar(),
              ),
              Expanded(
                child: child!,
              ),
            ],
          ),
        );
      },
    );
  }
}
