import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tv_indoor/app/controllers/sefaz_controller.dart';

class SefazStatusWidget extends StatelessWidget {
  const SefazStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final SefazController controller = Get.find<SefazController>();

    return Obx(() {
      if (controller.servicos.isEmpty && !controller.isLoading.value) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header compacto
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getStatusColor(controller.statusGeral.value),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'SEFAZ-GO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (controller.isLoading.value)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            // Lista de serviços compacta
            if (controller.servicos.isNotEmpty)
              ...controller.servicos.entries.map((entrada) {
                final nomeServico = _getNomeServico(entrada.key);
                final status = entrada.value;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          nomeServico,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      );
    });
  }

  String _getNomeServico(String chave) {
    switch (chave) {
      case 'nfe_autorizacao_4_00':
        return 'Autorização';
      case 'nfe_ret_autorizacao_4_00':
        return 'Ret. Autorização';
      case 'nfe_consulta_protocolo_4_00':
        return 'Consulta Protocolo';
      case 'nfe_status_servico_4_00':
        return 'Status Serviço';
      case 'nfe_consulta_cadastro_4_00':
        return 'Consulta Cadastro';
      case 'nfe_recepcao_evento_4_00':
        return 'Recepção Evento';
      case 'nfe_inutilizacao_4_00':
        return 'Inutilização';
      case 'nfe_distribuicao_dfe':
        return 'Distribuição DFe';
      default:
        return chave;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return Colors.green.shade600;
      case 'problema':
      case 'parcial':
        return Colors.orange.shade600;
      case 'offline':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }
}
