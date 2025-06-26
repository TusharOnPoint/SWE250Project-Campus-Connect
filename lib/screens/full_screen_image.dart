import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class FullScreenImage extends StatelessWidget {
  final ImageProvider image;
  final String heroTag;
  const FullScreenImage({
    super.key,
    required this.image,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),        // tap-to-dismiss
        child: Center(
          child: Hero(
            tag: heroTag,
            child: PhotoView(
              imageProvider: image,
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3,
              backgroundDecoration:
                  const BoxDecoration(color: Colors.transparent),
            ),
          ),
        ),
      ),
    );
  }
}
