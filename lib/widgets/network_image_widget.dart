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
    if (kIsWeb) {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ??
              Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ??
              const Center(child: Icon(Icons.broken_image, color: Colors.grey));
        },
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) =>
          placeholder ?? const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      errorWidget: (context, url, error) =>
          errorWidget ?? const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
    );
  }
}

/// A cross-platform network image provider.
/// Returns NetworkImage on web, CachedNetworkImageProvider on mobile.
ImageProvider appNetworkImageProvider(String url) {
  if (kIsWeb) {
    return NetworkImage(url);
  }
  return CachedNetworkImageProvider(url);
}
