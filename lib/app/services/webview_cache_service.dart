import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class WebViewCacheService {
  static const Duration cacheExpiry = Duration(hours: 1);
  
  static Future<String> getCachedContent(String url) async {
    try {
      final cacheFile = await _getCacheFile(url);
      
      if (await cacheFile.exists()) {
        final cacheData = jsonDecode(await cacheFile.readAsString());
        final cachedTime = DateTime.parse(cacheData['timestamp']);
        
        if (DateTime.now().difference(cachedTime) < cacheExpiry) {
          return cacheData['content'];
        }
      }
      
      // Se não tem cache válido, busca online
      return await _fetchAndCache(url);
    } catch (e) {
      return await _fetchAndCache(url);
    }
  }
  
  static Future<String> _fetchAndCache(String url) async {
    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      // Otimiza o HTML removendo elementos desnecessários
      String optimizedContent = _optimizeHtml(response.body);
      
      await _saveToCache(url, optimizedContent);
      return optimizedContent;
    }
    
    throw Exception('Falha ao carregar conteúdo');
  }
  
  static String _optimizeHtml(String html) {
    // Remove APENAS scripts específicos de analytics e ads - MANTÉM Qlik funcionando
    html = html.replaceAll(RegExp(r'<script[^>]*google-analytics[^>]*>.*?</script>', 
        multiLine: true, dotAll: true), '');
    html = html.replaceAll(RegExp(r'<script[^>]*googletagmanager[^>]*>.*?</script>', 
        multiLine: true, dotAll: true), '');
    html = html.replaceAll(RegExp(r'<script[^>]*facebook[^>]*>.*?</script>', 
        multiLine: true, dotAll: true), '');
    
    // Remove APENAS iframes de ads - NÃO remove outros iframes
    html = html.replaceAll(RegExp(r'<iframe[^>]*doubleclick[^>]*>.*?</iframe>', 
        multiLine: true, dotAll: true), '');
    html = html.replaceAll(RegExp(r'<iframe[^>]*googlesyndication[^>]*>.*?</iframe>', 
        multiLine: true, dotAll: true), '');
    
    // CSS otimizado SEM quebrar BI/Qlik
    html = html.replaceFirst('</head>', '''
      <style>
        /* Remove apenas elementos de publicidade */
        .ads, [class*="ad-"], [id*="ad-"] { display: none !important; }
        .popup { display: none !important; }
        
        /* Otimizações gerais sem quebrar funcionalidade */
        img { 
          loading: lazy !important; 
          max-width: 100% !important;
          height: auto !important;
        }
        
        /* Melhora performance de scroll */
        body {
          overflow-x: hidden !important;
          -webkit-overflow-scrolling: touch !important;
        }
        
        /* NÃO remove pointer-events - necessário para BI/Qlik funcionar */
        /* NÃO desabilita interação - BI precisa de cliques/hover */
      </style>
      </head>
    ''');
    
    return html;
  }
  
  static Future<File> _getCacheFile(String url) async {
    final directory = await getApplicationDocumentsDirectory();
    final hash = url.hashCode.toString();
    return File('${directory.path}/webview_cache_$hash.json');
  }
  
  static Future<void> _saveToCache(String url, String content) async {
    final cacheFile = await _getCacheFile(url);
    final cacheData = {
      'url': url,
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    await cacheFile.writeAsString(jsonEncode(cacheData));
  }
  
  static Future<void> clearCache() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync()
          .where((file) => file.path.contains('webview_cache_'))
          .cast<File>();
      
      for (final file in files) {
        await file.delete();
      }
    } catch (e) {
      print('Erro ao limpar cache: $e');
    }
  }
}
