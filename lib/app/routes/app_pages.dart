import 'package:get/instance_manager.dart';
import 'package:get/route_manager.dart';
import 'package:tv_indoor/app/controllers/config_controller.dart';
import 'package:tv_indoor/app/controllers/tv_indoor_controller.dart';
import 'package:tv_indoor/app/screens/config_screen.dart';
import 'package:tv_indoor/app/screens/tv_indoor_screen.dart';

class AppPages {

  static const INITIAL = '/config';


  static final routes = [
    GetPage(
      name: '/config', 
      page: () => ConfigScreen(),
      binding: BindingsBuilder(() {
        // registra a instância para que Get.find<ConfigController>() funcione
        Get.put(ConfigController(), permanent: true);
      }),
    ),
    GetPage(
      name: '/tv-indoor', 
      page: () => TvIndoorScreen(),
      binding: BindingsBuilder(() {
        Get.put(TvIndoorController());
      }),
    )
  ];
}