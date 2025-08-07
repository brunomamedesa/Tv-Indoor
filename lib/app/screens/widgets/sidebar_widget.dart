import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tv_indoor/app/controllers/connectivity_controller.dart';
import 'package:tv_indoor/app/controllers/webview_controller.dart';
import 'package:tv_indoor/app/screens/widgets/table_widget.dart';
import 'package:weather_icons/weather_icons.dart';
import 'package:intl/intl.dart';


class SideBar extends StatelessWidget {

  final WebviewController controller = Get.put(WebviewController());
  
  SideBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Container(
        clipBehavior: Clip.none,
        width: 250,
        height: double.infinity,
        decoration: const BoxDecoration(
          // borderRadius: BorderRadiusDirectional.only(),
          color:  Color.fromRGBO(51, 91, 64, 1.0),
        ),
        child: 
            Column(   
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Image.asset(
                            'assets/logos/Logo Rayquimica-1.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20,),
                // Widget de data e hora
                _buildDateTimeWidget(),
                const SizedBox(height: 15,),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 100,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Card(                             
                            elevation: 3,
                            clipBehavior: Clip.antiAlias,                          
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),            
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black,
                                    Colors.grey.shade900,
                                    Colors.grey.shade800,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        if(controller.previsaoTempo.isEmpty) ... [
                                          const Expanded(
                                            child: Center(
                                              child: CircularProgressIndicator(),
                                            ),
                                          )
                                        ] else ... [
                                          // Bloco de ícone, temperatura e descrição
                                          Builder(builder: (_) {
                                            final previsao = controller.previsaoTempo;
                                            final icone = previsao['icone'] as String?;
                                            final temp = previsao['temperatura_c'] as num?;
                                            final desc = previsao['descricao'] as String?;
                                            if (icone == null || temp == null || desc == null) {
                                              return const Center(
                                                child: SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.blue,
                                                  ),
                                                ),
                                              );
                                            }
                                            return Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    children: [
                                                      Row(
                                                        crossAxisAlignment: CrossAxisAlignment.center,
                                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                        children: [
                                                          controller.svgAnimado(icone),
                                                          const SizedBox(width: 8),
                                                          Text(
                                                            '${temp.toDouble().toStringAsFixed(1)} °C',
                                                            style: const TextStyle(
                                                              fontSize: 20,
                                                              height: 1,
                                                              color: Colors.white,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      // const SizedBox(height: 4),
                                                      Text(
                                                        desc,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          letterSpacing: 1,
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                        textAlign: TextAlign.center,
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                        softWrap: true,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            );
                                          }),
                                          // Bloco de vento
                                          Expanded(
                                            child: Builder(builder: (_) {
                                              final previsao = controller.previsaoTempo;
                                              final icVent = previsao['icone_vento'] as String?;
                                              final vento = previsao['vento_kmh'] as num?;
                                              if (icVent == null || vento == null) {
                                                // sem dados de vento, esconde o widget
                                                return const SizedBox.shrink();
                                              }
                                              return Row(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const BoxedIcon(
                                                    WeatherIcons.strong_wind,  // ícone de vento
                                                    size: 20,
                                                    color: Colors.white,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '${vento.toDouble().toStringAsFixed(1)} KM/H',
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }),
                                          ),
                                        ]
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30,),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: SizedBox(
                          width: double.infinity,
                          height: 80,
                          child: Row(
                            children: [
                              if(controller.loading.isTrue) ... [
                                const Expanded(
                                  child:  Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              ] else ... [
                                Expanded(
                                  child: ListView.builder(
                                    padding: const EdgeInsets.all(5),
                                    itemCount: controller.cotacoes.length,
                                    itemBuilder: (context, index) {
                                      
                                      final c = controller.cotacoes[index];
                          
                                      final arrow = c['variation'] >= 0 ? '▲' : '▼';
                                      final color = c['variation'] >= 0 ? Colors.green : Colors.red;
                          
                                      return Card(
                                        margin: const EdgeInsets.symmetric(vertical: 4),
                                        elevation: 3,
                                        child: ListTile(
                                          minTileHeight: 50,
                                          minLeadingWidth: 10,
                                          horizontalTitleGap: 10,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                                          leading:  c['symbol'] == null
                                          ? const Icon(Icons.currency_bitcoin, size: 18)
                                          : Text(
                                            c['symbol'],
                                            style: const TextStyle(fontSize: 18),
                                          ),
                                          title: Text(
                                            '${c['code']} • R\$ ${c['rate'].toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold
                                            ),
                                          ),
                                          trailing: Text(
                                            '$arrow ${c['variation'].abs().toStringAsFixed(2)}%',
                                            style: TextStyle(color: color, fontSize: 10),
                                          ),
                                          subtitle: Text(
                                            c['updatedAt'],
                                            softWrap: false,
                                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                                          ),
                                        ),
                                      );
                                    },
                                  
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                      ),
                      // const SizedBox(height: 30,),
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CotacaoTable(),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Widget de status de conectividade movido para baixo
                            _buildConnectivityStatus(),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
        );
    });
  }

  // Widget simples para mostrar status de conectividade
  Widget _buildConnectivityStatus() {
    try {
      final connectivityController = Get.find<ConnectivityController>();
      return Obx(() {
        final isConnected = connectivityController.isConnected.value;
        final connectionType = connectivityController.connectionType.value;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isConnected ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isConnected ? Colors.green : Colors.red,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isConnected ? Icons.wifi : Icons.wifi_off,
                color: isConnected ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                isConnected ? 'Conectado ($connectionType)' : 'Sem conexão',
                style: TextStyle(
                  color: isConnected ? Colors.green : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      });
    } catch (e) {
      // Se não conseguir encontrar o controller, mostra status neutro
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey, width: 1),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.help_outline, color: Colors.grey, size: 16),
            SizedBox(width: 6),
            Text(
              'Status desconhecido',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }
  }

  // Widget para mostrar data e hora
  Widget _buildDateTimeWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: StreamBuilder<DateTime>(
        stream: Stream.periodic(const Duration(seconds: 1), (_) {
          // Pegar horário de Brasília (UTC-3)
          final utcNow = DateTime.now().toUtc();
          final brasiliaTime = utcNow.subtract(const Duration(hours: 3));
          return brasiliaTime;
        }),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();
          
          final time = snapshot.data!;
          final formattedDate = DateFormat('dd \'de\' MMMM \'de\' yyyy', 'pt_BR').format(time);
          final formattedTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
          
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                formattedDate,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formattedTime,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}