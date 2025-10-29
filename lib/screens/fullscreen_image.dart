import 'package:flutter/material.dart';

class FullscreenImage extends StatelessWidget {
  const FullscreenImage({
    required this.image,
    required this.heroTag,
    super.key,
  });

  final ImageProvider image;
  final String heroTag;

  void _close(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _close(context),
        ),
      ),
      body: Center(
        child: Hero(
          tag: heroTag,
          child: InteractiveViewer(
            clipBehavior: Clip.none,
            minScale: 0.8,
            maxScale: 4,
            child: Image(image: image, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
