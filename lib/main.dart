import 'package:flutter/material.dart';
import 'screens/nasa_images.dart';
import 'screens/space_news.dart';

void main() => runApp(const SpaceExplorerApp());

class SpaceExplorerApp extends StatelessWidget {
  const SpaceExplorerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Space Explorer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9AA7FF),
          brightness: Brightness.dark,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(fontWeight: FontWeight.w800),
          titleLarge: TextStyle(fontWeight: FontWeight.w700),
          bodyMedium: TextStyle(color: Colors.white70, height: 1.35),
          labelLarge: TextStyle(color: Colors.white60),
        ),
      ),
      home: const _RootTabs(),
    );
  }
}

class _RootTabs extends StatefulWidget {
  const _RootTabs({super.key});
  @override
  State<_RootTabs> createState() => _RootTabsState();
}

class _RootTabsState extends State<_RootTabs> {
  int _index = 0;
  final _pages = const [
    NasaImagesScreen(),
    SpaceNewsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_index == 0 ? 'NASA Images' : 'Space News'),
        centerTitle: true,
      ),
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.photo_library_outlined), label: 'Images'),
          NavigationDestination(icon: Icon(Icons.newspaper), label: 'News'),
        ],
      ),
    );
  }
}
