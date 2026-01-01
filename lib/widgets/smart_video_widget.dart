import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Akıllı video widget - Asset ve HTTP URL'leri otomatik algılar
/// 
/// Kullanım:
/// ```dart
/// SmartVideoWidget(
///   videoUrl: 'assets/exercises/plank.mp4', // Asset path
///   // veya
///   videoUrl: 'https://example.com/video.mp4', // HTTP URL
///   autoPlay: true,
///   looping: true,
/// )
/// ```
class SmartVideoWidget extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool looping;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const SmartVideoWidget({
    Key? key,
    required this.videoUrl,
    this.autoPlay = true,
    this.looping = true,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  @override
  State<SmartVideoWidget> createState() => _SmartVideoWidgetState();
}

class _SmartVideoWidgetState extends State<SmartVideoWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  /// URL'nin asset path mi yoksa HTTP URL mi olduğunu kontrol eder
  bool get _isAssetPath {
    return !widget.videoUrl.startsWith('http://') && 
           !widget.videoUrl.startsWith('https://') &&
           !widget.videoUrl.startsWith('file://');
  }

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(SmartVideoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeController();
      _initializeVideo();
    }
  }

  void _initializeVideo() {
    if (widget.videoUrl.isEmpty) {
      setState(() => _hasError = true);
      return;
    }

    try {
      // Asset path ise VideoPlayerController.asset kullan
      if (_isAssetPath) {
        _controller = VideoPlayerController.asset(widget.videoUrl);
      } else {
        // HTTP URL ise VideoPlayerController.network kullan
        _controller = VideoPlayerController.network(widget.videoUrl);
      }

      _controller!
        ..setLooping(widget.looping)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isInitialized = true;
              _hasError = false;
            });
            if (widget.autoPlay) {
              _controller!.play();
            }
          }
        }).catchError((error) {
          if (mounted) {
            setState(() {
              _hasError = true;
              _isInitialized = false;
            });
          }
        });
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isInitialized = false;
        });
      }
    }
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hata durumu
    if (_hasError) {
      return widget.errorWidget ?? _buildErrorWidget();
    }

    // Yükleniyor durumu
    if (!_isInitialized || _controller == null) {
      return widget.placeholder ?? _buildPlaceholder();
    }

    // Video oynatıcı
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: VideoPlayer(_controller!),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey.shade200,
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey.shade300,
      child: const Icon(
        Icons.videocam_off,
        size: 40,
        color: Colors.grey,
      ),
    );
  }
}

