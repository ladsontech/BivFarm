import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

/// A cross-platform network image widget.
class AppNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.memCacheWidth = 400, // Reduced from 600 for better memory usage
    this.memCacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: memCacheWidth,
        cacheHeight: memCacheHeight,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ??
              _ShimmerPlaceholder(width: width, height: height);
        },
        errorBuilder: (context, error, stackTrace) =>
            errorWidget ?? _ErrorPlaceholder(width: width, height: height),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      fadeInDuration:
          const Duration(milliseconds: 300), // Slightly longer for smoothness
      placeholder: (context, url) =>
          placeholder ?? _ShimmerPlaceholder(width: width, height: height),
      errorWidget: (context, url, error) =>
          errorWidget ?? _ErrorPlaceholder(width: width, height: height),
    );
  }
}

class _ShimmerPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  const _ShimmerPlaceholder({this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        color: Colors.white,
      ),
    );
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  const _ErrorPlaceholder({this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      color: Colors.grey[200],
      child: const Center(
          child: Icon(Icons.broken_image, color: Colors.grey, size: 20)),
    );
  }
}

/// A cross-platform network image provider.
ImageProvider appNetworkImageProvider(String url) {
  if (kIsWeb) {
    return NetworkImage(url);
  }
  return CachedNetworkImageProvider(url);
}

/// Prefetch a list of image URLs into memory/disk cache.
/// Call this when product lists load to warm up the cache.
Future<void> prefetchProductImages(
    BuildContext context, List<String> imageUrls) async {
  for (final url in imageUrls) {
    if (url.isEmpty || url.startsWith('assets/')) continue;
    try {
      if (kIsWeb) {
        // On web, precacheImage uses the browser's cache
        await precacheImage(NetworkImage(url), context);
      } else {
        await precacheImage(CachedNetworkImageProvider(url), context);
      }
    } catch (_) {
      // Silently ignore prefetch failures
    }
  }
}
