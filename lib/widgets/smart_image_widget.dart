import 'package:flutter/material.dart';

/// Akıllı görsel widget - Asset ve HTTP URL'leri otomatik algılar
/// 
/// Kullanım:
/// ```dart
/// SmartImageWidget(
///   imageUrl: 'assets/exercises/plank.jpg', // Asset path
///   // veya
///   imageUrl: 'https://example.com/image.jpg', // HTTP URL
///   fit: BoxFit.cover,
/// )
/// ```
class SmartImageWidget extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const SmartImageWidget({
    Key? key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  /// URL'nin asset path mi yoksa HTTP URL mi olduğunu kontrol eder
  bool get _isAssetPath {
    return !imageUrl.startsWith('http://') && 
           !imageUrl.startsWith('https://') &&
           !imageUrl.startsWith('file://');
  }

  @override
  Widget build(BuildContext context) {
    // Boş URL kontrolü
    if (imageUrl.isEmpty) {
      return _buildErrorWidget();
    }

    // Asset path ise Image.asset kullan
    if (_isAssetPath) {
      return Image.asset(
        imageUrl,
        fit: fit,
        width: width,
        height: height,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          // Frame yüklenmişse görseli göster
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }
          // Yükleniyor durumunda placeholder göster
          return placeholder ?? _buildPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? _buildErrorWidget();
        },
      );
    }

    // HTTP URL ise Image.network kullan
    return Image.network(
      imageUrl,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? _buildPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? _buildErrorWidget();
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade300,
      child: const Icon(
        Icons.fitness_center,
        size: 40,
        color: Colors.grey,
      ),
    );
  }
}

