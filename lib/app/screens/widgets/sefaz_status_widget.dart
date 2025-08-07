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
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.95),
              Colors.grey.shade50.withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCabecalho(controller),
            const SizedBox(height: 20),
            if (controller.isLoading.value)
              _buildLoadingState()
            else if (controller.servicos.isNotEmpty)
              _buildListaServicos(controller)
            else
              _buildEmptyState(),
            const SizedBox(height: 16),
            _buildRodape(controller),
          ],
        ),
      );
    });
  }

  Widget _buildCabecalho(SefazController controller) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getStatusColor(controller.statusGeral.value).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.account_balance,
            color: _getStatusColor(controller.statusGeral.value),
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SEFAZ Goiás',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _getStatusColor(controller.statusGeral.value),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getStatusTexto(controller.statusGeral.value),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(controller.statusGeral.value),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (controller.isLoading.value)
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          IconButton(
            onPressed: () => controller.atualizarAgora(),
            icon: Icon(
              Icons.refresh,
              color: Colors.grey.shade600,
              size: 24,
            ),
            tooltip: 'Atualizar agora',
          ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Carregando status dos serviços...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.cloud_off,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Não foi possível carregar os dados',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaServicos(SefazController controller) {
    final servicosFormatados = controller.servicosFormatados;
    
    return Column(
      children: servicosFormatados.entries.map((entrada) {
        final nome = entrada.value['nome']!;
        final status = entrada.value['status']!;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _getStatusColor(status).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getStatusColor(status).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  nome,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusTexto(status),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(status),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRodape(SefazController controller) {
    final contadores = controller.contadores;
    final ultimaAtualizacao = controller.ultimaAtualizacao.value;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildContador('Online', contadores['online']!, Colors.green),
              _buildContador('Problemas', contadores['problema']!, Colors.orange),
              _buildContador('Offline', contadores['offline']!, Colors.red),
              _buildContador('Total', contadores['total']!, Colors.blue),
            ],
          ),
        ),
        if (ultimaAtualizacao.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Última atualização: ${_formatarDataHora(ultimaAtualizacao)}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContador(String label, int valor, Color cor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          valor.toString(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: cor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
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

  String _getStatusTexto(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return 'Operacional';
      case 'problema':
        return 'Instável';
      case 'offline':
        return 'Indisponível';
      case 'parcial':
        return 'Parcial';
      case 'carregando':
        return 'Carregando...';
      default:
        return 'Desconhecido';
    }
  }

  String _formatarDataHora(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      final agora = DateTime.now();
      final diferenca = agora.difference(dateTime);

      if (diferenca.inMinutes < 1) {
        return 'Agora mesmo';
      } else if (diferenca.inMinutes < 60) {
        return '${diferenca.inMinutes} min atrás';
      } else if (diferenca.inHours < 24) {
        return '${diferenca.inHours}h atrás';
      } else {
        return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return 'Data inválida';
    }
  }
}
