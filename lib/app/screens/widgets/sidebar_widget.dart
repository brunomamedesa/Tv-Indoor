import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tv_indoor/app/controllers/config_controller.dart';
import 'package:tv_indoor/app/controllers/webview_controller.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
        width: 240,
        height: double.infinity,
        decoration: const BoxDecoration(
          // borderRadius: BorderRadiusDirectional.only(),
          color:  Color.fromRGBO(51, 91, 64, 1.0),
        ),
        child: 
            Column(   
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 12, top: 8, ),
                          child: Text(
                            'TV',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 50,
                              height: 0
                            ),
                          )
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 23, top: 15),
                          child: Text(
                            'indoor',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 38,
                              height: 0,
                              letterSpacing: 1.5
                            ),
                          )
                        ),
                      ],
                    ),
                    Transform.translate(
                      offset: const Offset(40, -10), // x = 12 para alinhar o left, y = -6 para subir
                      child: const Text(
                        'tv corporativa',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                          fontSize: 15,
                          letterSpacing: 2,
                          height: 1.0,
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20,),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 95,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: WebViewWidget(controller: controller.webview),
                        ),
                      ),
                      SizedBox(height: 20,),
                      Expanded(
                        flex: 2,
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
                                        contentPadding: EdgeInsets.symmetric(horizontal: 3),
                                        leading:  c['code'] == 'BTC'
                                        ? Icon(Icons.currency_bitcoin, size: 18)
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
                        )
                      ),
                      const SizedBox(height: 20,),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset(
                          'assets/img-sidebar/image-side.png',
                        ),
                      ),
                      const SizedBox(height: 30,),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset(
                          'assets/logos/logo-sidebar.png',
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
}