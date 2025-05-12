import 'package:flutter_cache_manager/flutter_cache_manager.dart';


class MediaCacheManager extends CacheManager {
  static const _key = 'mediaCache';


  // A instância única (singleton)
  static final MediaCacheManager _instance = MediaCacheManager._();

  factory MediaCacheManager() => _instance;

    MediaCacheManager._()
      : super(
          Config(
            _key,
            // periodo de reset do cache
            stalePeriod: const Duration(days: 365),
            // número máximo de objetos em cache
            maxNrOfCacheObjects: 200,
            repo: JsonCacheInfoRepository(databaseName: _key),
            fileService: HttpFileService(),
          ),
        );

}