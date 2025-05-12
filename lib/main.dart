import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tv_indoor/app/controllers/tv_indoor_controller.dart';
import 'package:tv_indoor/app/routes/app_pages.dart';
import 'package:tv_indoor/app/screens/widgets/noticias_widget.dart';
import 'package:tv_indoor/app/screens/widgets/sidebar_widget.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';          // ← import dotenv

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  initializeDateFormatting('pt_BR');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
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
                child: Column(
                  children: [
                    Expanded(
                      flex: 5,
                      child: child!
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        color: const Color.fromRGBO(51, 91, 64, 1.0),
                        child: Noticias()
                      )
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
