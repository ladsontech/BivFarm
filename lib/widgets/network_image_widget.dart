import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A cross-platform network image widget.
/// Uses Image.network on web (since cached_network_image has issues on web)
/// and CachedNetworkImage on mobile for caching support.
class AppNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) =>
          placeholder ?? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green)),
      errorWidget: (context, url, error) =>
          errorWidget ?? const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
    );
  }
}

/// A cross-platform network image provider.
ImageProvider appNetworkImageProvider(String url) {
  return CachedNetworkImageProvider(url);
}
