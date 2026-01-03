import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';

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
      debugPrint('[SmartImageWidget] Empty imageUrl, showing error widget');
      return _buildErrorWidget();
    }

    // gs:// URL kontrolü - bu URL'ler doğrudan kullanılamaz!
    if (imageUrl.startsWith('gs://')) {
      debugPrint('[SmartImageWidget] ERROR: gs:// URL cannot be used directly! URL: $imageUrl');
      debugPrint('[SmartImageWidget] Use StorageService.getExerciseImageUrl() to convert to download URL');
      return _buildErrorWidget();
    }

    // Debug: URL'yi logla
    debugPrint('[SmartImageWidget] Loading image: $imageUrl (isAsset: $_isAssetPath)');

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
          debugPrint('[SmartImageWidget] Asset load error for $imageUrl: $error');
          return errorWidget ?? _buildErrorWidget();
        },
      );
    }

    // HTTP URL ise CachedNetworkImage kullan (CORS sorunlarını daha iyi handle eder)
    // Web'de doğrudan Image.network kullan (CachedNetworkImage web'de sorunlu olabilir)
    if (kIsWeb) {
      return Image.network(
        imageUrl,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            debugPrint('[SmartImageWidget] Web image loaded: $imageUrl');
            return child;
          }
          return placeholder ?? _buildPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('[SmartImageWidget] Web network image error for $imageUrl: $error');
          debugPrint('[SmartImageWidget] Stack trace: $stackTrace');
          return errorWidget ?? _buildErrorWidget();
        },
      );
    }

    // Mobil için CachedNetworkImage kullan
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      placeholder: (context, url) => placeholder ?? _buildPlaceholder(),
      errorWidget: (context, url, error) {
        debugPrint('[SmartImageWidget] CachedNetworkImage error for $imageUrl: $error');
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

