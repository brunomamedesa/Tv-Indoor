import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tv_indoor/app/controllers/connectivity_controller.dart';

class ConnectivityIndicator extends StatelessWidget {
  const ConnectivityIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final ConnectivityController connectivityController = Get.find();

    return Obx(() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: connectivityController.isConnected.value 
            ? Colors.green.withOpacity(0.9) 
            : Colors.red.withOpacity(0.9),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              connectivityController.isConnected.value 
                ? _getConnectionIcon(connectivityController.connectionType.value)
                : Icons.signal_wifi_off,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              connectivityController.isConnected.value 
                ? _getConnectionText(connectivityController.connectionType.value)
                : 'Sem Internet',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 2,
                    color: Colors.black45,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  IconData _getConnectionIcon(String connectionType) {
    switch (connectionType) {
      case 'wifi':
        return Icons.wifi;
      case 'ethernet':
        return Icons.lan;
      case 'mobile':
        return Icons.signal_cellular_alt;
      default:
        return Icons.network_check;
    }
  }

  String _getConnectionText(String connectionType) {
    switch (connectionType) {
      case 'wifi':
        return 'WiFi Conectado';
      case 'ethernet':
        return 'Ethernet Conectado';
      case 'mobile':
        return 'Móvel Conectado';
      default:
        return 'Conectado';
    }
  }
}
