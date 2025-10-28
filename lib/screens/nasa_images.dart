import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/space_cache.dart';
import '../widgets/app_error.dart';
import 'fullscreen_image.dart';

class NasaImagesScreen extends StatefulWidget {
  const NasaImagesScreen({super.key});

  @override
  State<NasaImagesScreen> createState() => _NasaImagesScreenState();
}

class _NasaImagesScreenState extends State<NasaImagesScreen>
    with AutomaticKeepAliveClientMixin {
  final _controller = TextEditingController();
  Future<List<_NasaItem>>? _future;

  Future<List<_NasaItem>> _search(String q) async {
    final uri = Uri.https('images-api.nasa.gov', '/search', {
      'q': q,
      'media_type': 'image',
    });
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('NASA Images ${res.statusCode}');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final items = (json['collection']?['items'] as List?) ?? [];

    return items
        .map<_NasaItem>((e) {
          final data =
              ((e['data'] as List?)?.cast<Map<String, dynamic>>().first) ?? {};
          final links =
              ((e['links'] as List?)?.cast<Map<String, dynamic>>()) ?? const [];
          final thumb = links.isNotEmpty
              ? links.first['href'] as String?
              : null;
          return _NasaItem(
            title: (data['title'] ?? '') as String,
            description: (data['description'] ?? '') as String? ?? '',
            previewUrl: thumb ?? '',
          );
        })
        .where((x) => x.previewUrl.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // ловим тап и по «пустым» зонам
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        children: [
          _SearchBar(
            controller: _controller,
            onSubmit: (q) {
              final query = q.trim().isEmpty ? 'moon' : q.trim();
              setState(() {
                _future = _search(query);
              });
              FocusScope.of(context).unfocus();
            },
            onClear: () {
              setState(() {
                _controller.clear();
                _future = null;
              });
              FocusScope.of(context).unfocus();
            },
          ),
          Expanded(
            child: FutureBuilder<List<_NasaItem>>(
              future: _future,
              builder: (context, snapshot) {
                // Обрабатываем состояние, когда future ещё не задан (ConnectionState.none)
                if (snapshot.connectionState == ConnectionState.none) {
                  return const Center(
                    child: Text('Введите запрос и нажмите поиск'),
                  );
                }

                // Явная обработка загрузки
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Понятный вывод ошибки
                if (snapshot.hasError) {
                  return AppError(text: 'Ошибка: ${snapshot.error}');
                }

                // Защита от null и отсутствия данных
                final data = snapshot.data;
                if (data == null) {
                  return const AppError(text: 'Нет данных');
                }

                // Пустой результат
                if (data.isEmpty) {
                  return const AppError(text: 'Ничего не найдено');
                }

                // Используем уже проверенный список
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: data.length,
                  itemBuilder: (_, i) => _ImageTile(item: data[i]),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _NasaItem {
  _NasaItem({
    required this.title,
    required this.description,
    required this.previewUrl,
  });
  final String title;
  final String description;
  final String previewUrl;
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({required this.item});
  final _NasaItem item;

  @override
  Widget build(BuildContext context) {
    final provider = CachedNetworkImageProvider(
      item.previewUrl,
      cacheManager: SpaceCache.images,
      cacheKey: Uri.parse(item.previewUrl).pathSegments.last,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: item.previewUrl,
            child: CachedNetworkImage(
              imageUrl: item.previewUrl,
              cacheManager: SpaceCache.images,
              cacheKey: Uri.parse(item.previewUrl).pathSegments.last,
              fit: BoxFit.cover,
              fadeInDuration: Duration.zero,
              placeholder: (context, url) => const SizedBox.shrink(),
              errorWidget: (context, url, err) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white54,
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FullscreenImage(
                      image: provider,
                      heroTag: item.previewUrl,
                    ),
                  ),
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onSubmit,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmit;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final hasText = value.text.isNotEmpty;
          return TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (q) {
              if (q.trim().isEmpty) return;
              onSubmit(q.trim());
              FocusScope.of(context).unfocus();
            },
            decoration: InputDecoration(
              hintText: 'Поиск по NASA Images',
              filled: true,
              fillColor: Colors.white12,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: hasText
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Сбросить',
                      onPressed: onClear,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          );
        },
      ),
    );
  }
}
