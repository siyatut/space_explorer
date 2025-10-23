import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class SpaceCache {
  static final BaseCacheManager images = CacheManager(
    Config(
      'space_images_cache',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 200,
      repo: JsonCacheInfoRepository(databaseName: 'space_images_cache'),
      fileService: HttpFileService(),
    ),
  );
}
