import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:mobile_device_identifier/mobile_device_identifier.dart';
import 'package:dio/dio.dart';

class ConfigController extends GetxController {
  
  final RxString deviceId = ''.obs;
  final RxBool isLoading = false.obs;
  final RxMap<String, dynamic> devideData = <String, dynamic>{}.obs;

  final baseUrl = kDebugMode ? dotenv.env['BASE_URL_PROD'] : dotenv.env['BASE_URL_PROD'];
  final apiKey = dotenv.env['API_KEY'];

  final dio = Dio();


  @override
  Future<void> onInit() async {
    super.onInit();
    deviceId.value = (await getDeviceId())!;
    await autenticarDispositivo();
    
  }


  Future<String?> getDeviceId() async{
    return await MobileDeviceIdentifier().getDeviceId(); 
  }

  Future<void> autenticarDispositivo() async {
    try {
      isLoading.value = true;
      final response = await dio.get(
        '$baseUrl/dispositivo/${deviceId.value}', 
        options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
        })
      );
      print(response.data);
      devideData.value = response.data;
      print(devideData);

    }
    on DioException catch (e) {
      print(e.response);
    }
    catch (e) {
      print(e); 
    }
  }

}