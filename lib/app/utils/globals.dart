
import 'package:get/get.dart';
import 'package:intl/intl.dart';


  final RxBool configurado = false.obs;
  
  String formatDateTimeBR(String isoDate) {
    final dt = DateTime.parse(isoDate).toLocal();
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }