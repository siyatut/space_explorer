import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../services/space_cache.dart';

class SpaceNewsScreen extends StatefulWidget {
  const SpaceNewsScreen({super.key});
  @override
  State<SpaceNewsScreen> createState() => _SpaceNewsScreenState();
}

class _SpaceNewsScreenState extends State<SpaceNewsScreen> 
with AutomaticKeepAliveClientMixin {
  late Future<List<_Article>> _future = _fetch();

  Future<List<_Article>> _fetch() async {
    final uri = Uri.parse(
      'https://api.spaceflightnewsapi.net/v4/articles/?limit=20',
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw Exception('News ${res.statusCode}');
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final results = (json['results'] as List).cast<Map<String, dynamic>>();
    return results.map((j) => _Article.fromJson(j)).toList();
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: () async => setState(() => _future = _fetch()),
      child: FutureBuilder<List<_Article>>(
        future: _future,
        builder: (c, s) {
          if (s.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (s.hasError) {
            return Center(
              child: Text(
                'Ошибка: ${s.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }
          final list = s.data!;
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _NewsCard(article: list[i], onOpen: _open),
          );
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _Article {

  _Article({
    required this.title,
    required this.summary,
    required this.site,
    required this.publishedAt,
    required this.url,
    required this.imageUrl,
  });

  factory _Article.fromJson(Map<String, dynamic> j) => _Article(
    title: j['title'] ?? '',
    summary: j['summary'] ?? '',
    site: j['news_site'] ?? '',
    publishedAt: DateTime.parse(j['published_at']),
    url: j['url'] ?? '',
    imageUrl: j['image_url'] as String?,
  );
  final String title;
  final String summary;
  final String site;
  final DateTime publishedAt;
  final String url;
  final String? imageUrl;
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.article, required this.onOpen});
  final _Article article;
  final void Function(String url) onOpen;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onOpen(article.url),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.imageUrl != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: article.imageUrl!,
                  cacheManager: SpaceCache.images,
                  cacheKey: Uri.parse(article.imageUrl!).pathSegments.last,
                  fit: BoxFit.cover,
                  fadeInDuration: Duration.zero, // ← без fade-in
                  placeholder: (_, __) => const SizedBox.shrink(),
                  errorWidget: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${article.site} • ${_fmt(article.publishedAt)}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.summary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year;
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$d.$m.$y';
  }
}
