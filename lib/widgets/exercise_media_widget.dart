import 'package:flutter/material.dart';
import 'smart_image_widget.dart';
import 'smart_video_widget.dart';
import '../models/exercise.dart';

/// Unified egzersiz medya widget - Görsel ve video için tek widget
/// 
/// Öncelik sırası:
/// 1. instructionVideoAsset (video varsa)
/// 2. instructionGifUrl (GIF varsa)
/// 3. imageUrl (görsel)
/// 
/// Kullanım:
/// ```dart
/// ExerciseMediaWidget(
///   exercise: exercise,
///   width: 200,
///   height: 200,
/// )
/// ```
class ExerciseMediaWidget extends StatelessWidget {
  final Exercise exercise;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool autoPlayVideo;
  final bool loopingVideo;
  final Widget? placeholder;
  final Widget? errorWidget;

  const ExerciseMediaWidget({
    Key? key,
    required this.exercise,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.autoPlayVideo = true,
    this.loopingVideo = true,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. Öncelik: Video varsa video göster
    if (exercise.instructionVideoAsset != null && 
        exercise.instructionVideoAsset!.isNotEmpty) {
      return SmartVideoWidget(
        videoUrl: exercise.instructionVideoAsset!,
        autoPlay: autoPlayVideo,
        looping: loopingVideo,
        width: width,
        height: height,
        placeholder: placeholder,
        errorWidget: errorWidget,
      );
    }

    // 2. İkinci öncelik: GIF varsa GIF göster
    if (exercise.instructionGifUrl != null && 
        exercise.instructionGifUrl!.isNotEmpty) {
      return SmartImageWidget(
        imageUrl: exercise.instructionGifUrl!,
        fit: fit,
        width: width,
        height: height,
        placeholder: placeholder,
        errorWidget: errorWidget,
      );
    }

    // 3. Son öncelik: Görsel göster
    return SmartImageWidget(
      imageUrl: exercise.imageUrl,
      fit: fit,
      width: width,
      height: height,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }
}

