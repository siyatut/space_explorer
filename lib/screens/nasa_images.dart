import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import '../services/space_cache.dart';

class NasaImagesScreen extends StatefulWidget {
  const NasaImagesScreen({super.key});

  @override
  State<NasaImagesScreen> createState() => _NasaImagesScreenState();
}

class _NasaImagesScreenState extends State<NasaImagesScreen> 
   with AutomaticKeepAliveClientMixin {
  
  final _controller = TextEditingController(text: 'nebula');
  Future<List<_NasaItem>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _search('nebula');
  }

  Future<List<_NasaItem>> _search(String q) async {
    final uri = Uri.parse(
      'https://images-api.nasa.gov/search?q=$q&media_type=image',
    );
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
    return Column(
      children: [
        _SearchBar(
          controller: _controller,
          onSubmit: (q) {
            if (q.trim().isEmpty) return;
            setState(() => _future = _search(q.trim()));
          },
        ),
        Expanded(
          child: FutureBuilder<List<_NasaItem>>(
            future: _future,
            builder: (c, s) {
              if (s.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (s.hasError) {
                return _Error(text: 'Ошибка: ${s.error}');
              }
              final list = s.data!;
              if (list.isEmpty) {
                return const _Error(text: 'Ничего не найдено');
              }
              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: list.length,
                itemBuilder: (_, i) => _ImageTile(item: list[i]),
              );
            },
          ),
        ),
      ],
    ); 
  }

  @override
  bool get wantKeepAlive => true;
}

class _NasaItem {
  final String title;
  final String description;
  final String previewUrl;
  _NasaItem({
    required this.title,
    required this.description,
    required this.previewUrl,
  });
}

class _ImageTile extends StatelessWidget {
  final _NasaItem item;
  const _ImageTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: item.previewUrl,
            cacheManager: SpaceCache.images,
            cacheKey: Uri.parse(item.previewUrl).pathSegments.last,
            fit: BoxFit.cover,
            fadeInDuration: Duration.zero,
            placeholder: (_, __) => const SizedBox.shrink(),
            errorWidget: (_, __, ___) =>
                const Icon(Icons.broken_image_outlined, color: Colors.white54),
          ),
          Container(
            alignment: Alignment.bottomLeft,
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
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmit;
  const _SearchBar({required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onSubmitted: onSubmit,
        decoration: InputDecoration(
          hintText: 'Поиск по NASA Images… (e.g. nebula, galaxy, moon)',
          filled: true,
          fillColor: Colors.white12,
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  final String text;
  const _Error({required this.text});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: const TextStyle(color: Colors.redAccent)),
      ),
    );
  }
}
