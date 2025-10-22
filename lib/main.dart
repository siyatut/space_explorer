import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart'; // для открытия видео в браузере (необязательно, но удобно)

void main() => runApp(const SpaceExplorerApp());

const nasaBase = 'https://api.nasa.gov';
const nasaKey = String.fromEnvironment('NASA_KEY', defaultValue: 'DEMO_KEY');

class SpaceExplorerApp extends StatelessWidget {
  const SpaceExplorerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Space Explorer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF9AA7FF), brightness: Brightness.dark),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontWeight: FontWeight.w800),
          bodyMedium: TextStyle(color: Colors.white70, height: 1.35),
          labelLarge: TextStyle(color: Colors.white70),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// ======== МОДЕЛЬ APOD ========
class Apod {
  final String title;
  final String date;
  final String mediaType; // "image" | "video"
  final String url;       // для image: картинка; для video: ссылка на страницу (YouTube/Vimeo)
  final String? thumb;    // thumbnail_url для видео (если есть)
  final String explanation;

  Apod({
    required this.title,
    required this.date,
    required this.mediaType,
    required this.url,
    required this.explanation,
    this.thumb,
  });

  factory Apod.fromJson(Map<String, dynamic> j) => Apod(
        title: j['title'] ?? '',
        date: j['date'] ?? '',
        mediaType: j['media_type'] ?? 'image',
        url: j['url'] ?? '',
        thumb: j['thumbnail_url'], // приходит, когда media_type = video и добавлен &thumbs=true
        explanation: j['explanation'] ?? '',
      );
}

// ======== ЭКРАН HOME ========
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<Apod> _apod = _fetchApod();

  Future<Apod> _fetchApod() async {
    final uri = Uri.parse('$nasaBase/planetary/apod?api_key=$nasaKey&thumbs=true');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('APOD HTTP ${res.statusCode}: ${res.body}');
    }
    return Apod.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Space Explorer'), centerTitle: true),
      body: FutureBuilder<Apod>(
        future: _apod,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Ошибка: ${snap.error}', style: const TextStyle(color: Colors.redAccent)));
          }
          final apod = snap.data!;
          final imageUrl = apod.mediaType == 'video' ? (apod.thumb ?? '') : apod.url;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(apod.title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(apod.date, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 12),
              if (imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(imageUrl, fit: BoxFit.cover, loadingBuilder: _loadingBuilder),
                )
              else
                _VideoPlaceholder(url: apod.url),
              const SizedBox(height: 12),
              if (apod.mediaType == 'video')
                FilledButton.icon(
                  onPressed: () => _openUrl(apod.url),
                  icon: const Icon(Icons.play_circle),
                  label: const Text('Открыть видео'),
                ),
              const SizedBox(height: 12),
              Text(apod.explanation),
            ],
          );
        },
      ),
    );
  }

  Widget _loadingBuilder(BuildContext _, Widget child, ImageChunkEvent? evt) {
    if (evt == null) return child;
    final progress = evt.expectedTotalBytes != null
        ? evt.cumulativeBytesLoaded / evt.expectedTotalBytes!
        : null;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(color: Colors.white10),
          CircularProgressIndicator(value: progress),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось открыть ссылку')),
        );
      }
    }
  }
}

// Плашка, если нет thumbnail для видео
class _VideoPlaceholder extends StatelessWidget {
  final String url;
  const _VideoPlaceholder({required this.url});
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16/9,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.play_circle_outline, size: 48),
            const SizedBox(height: 8),
            Text('Видео: $url', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
          ]),
        ),
      ),
    );
  }
}
