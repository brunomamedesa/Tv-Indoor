import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tv_indoor/app/controllers/webview_controller.dart';

class CotacaoTable extends StatelessWidget {

  CotacaoTable({super.key});
  WebviewController controller = Get.find<WebviewController>();

  @override
  Widget build(BuildContext context) {
    // estilo de texto para cabeçalho e corpo
    const headerStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontSize: 11,
      
    );
    const bodyStyle = TextStyle(
      color: Colors.black,
      fontSize: 11,
      fontWeight: FontWeight.bold
    );

    // célula de cabeçalho (permite escolher se terá fundo cinza ou não)
    Widget headerCell(String text, {bool gray = false}) => Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      alignment: Alignment.center,
      color: Colors.grey.shade600,
      child: Text(text, style: headerStyle, softWrap: false),
    );

    // célula de corpo (alinhamento à esquerda, direita ou centro)
    Widget bodyCell(String text, {Alignment align = Alignment.centerLeft}) =>
      Container(
        constraints: const BoxConstraints(minHeight: 50), // mesma altura
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        color: Colors.white,
        alignment: align,
        child: Text(
          text,
          style: bodyStyle,
        ),
      );

    return Obx(() {
      final semana = controller.cotacaoMetais['dia'].toString().replaceFirst('Média', '');
      if(controller.cotacaoMetais.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.black,),
        );
      } 
      return SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(
                child: Material(
                    // 1. Material já desenha a borda arredondada
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade500, width: .6),
                  ),
                  clipBehavior: Clip.hardEdge,           // 2. clipa o conteúdo
                  color: Colors.white,                   // (fundo da célula)
                  child: Table(
                    // 3. só linhas internas (a externa o Material já desenhou)
                    border: TableBorder.symmetric(
                      inside: BorderSide(color: Colors.grey.shade400, width: .6),
                    ),
                    // 4. Intrinsic faz a largura ser exatamente a do conteúdo
                    columnWidths: const {
                      0: IntrinsicColumnWidth(), // SEMANA
                      1: IntrinsicColumnWidth(),
                      2: IntrinsicColumnWidth(),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      TableRow(children: [
                        headerCell('LME'),
                        headerCell('COBRE'),
                        headerCell('DÓLAR'),
                      ]),
                      TableRow(children: [
                        bodyCell(semana),
                        bodyCell(controller.cotacaoMetais['cobre'].toString(),
                                align: Alignment.centerRight),
                        bodyCell(controller.cotacaoMetais['dolar'].toString(),
                                align: Alignment.centerRight),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },);
  
  }
}
