import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../utils/barbell_path_analysis.dart';

class BarbellAnalysisResult {
  const BarbellAnalysisResult({
    required this.samples,
    required this.framesAnalyzed,
    required this.framesWithPose,
    this.warning,
  });

  final List<BarbellSample> samples;
  final int framesAnalyzed;
  final int framesWithPose;
  final String? warning;

  bool get ok => samples.length >= 6;
}

/// Ekstrakcja klatek + ML Kit Pose — tor sztangi z nadgarstków (offline).
class BarbellVideoAnalyzer {
  static const _maxFrames = 48;
  static const _minLikelihood = 0.35;

  static Future<BarbellAnalysisResult> analyzeFile(String videoPath) async {
    final file = File(videoPath);
    if (!await file.exists()) {
      throw Exception('Plik wideo nie istnieje.');
    }

    final controller = VideoPlayerController.file(file);
    await controller.initialize();
    final duration = controller.value.duration;
    await controller.dispose();

    if (duration.inMilliseconds < 500) {
      throw Exception('Nagranie jest zbyt krótkie (minimum ~0,5 s).');
    }

    final detector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.single,
        model: PoseDetectionModel.accurate,
      ),
    );

    final rawSamples = <BarbellSample>[];
    var framesAnalyzed = 0;
    var framesWithPose = 0;

    final frameCount = math.min(
      _maxFrames,
      math.max(12, (duration.inMilliseconds / 50).round()),
    );

    final tempDir = await getTemporaryDirectory();

    try {
      for (var i = 0; i < frameCount; i++) {
        final ms = frameCount <= 1
            ? 0
            : (duration.inMilliseconds * i / (frameCount - 1)).round();
        final bytes = await VideoThumbnail.thumbnailData(
          video: videoPath,
          imageFormat: ImageFormat.JPEG,
          timeMs: ms,
          quality: 72,
        );
        if (bytes == null) continue;
        framesAnalyzed++;

        final size = await _decodeSize(bytes);
        if (size == null) continue;

        final tempPath = '${tempDir.path}/barbell_frame_$i.jpg';
        await File(tempPath).writeAsBytes(bytes, flush: true);

        final inputImage = InputImage.fromFilePath(tempPath);
        final poses = await detector.processImage(inputImage);
        if (poses.isEmpty) continue;

        final sample = _sampleFromPose(
          poses.first,
          ms / 1000.0,
          size.width,
          size.height,
        );
        if (sample != null) {
          framesWithPose++;
          rawSamples.add(sample);
        }
      }
    } finally {
      await detector.close();
    }

    if (rawSamples.length < 6) {
      return BarbellAnalysisResult(
        samples: const [],
        framesAnalyzed: framesAnalyzed,
        framesWithPose: framesWithPose,
        warning:
            'Za mało klatek z wykrytą pozą ($framesWithPose/$framesAnalyzed). '
            'Nagraj z profilu, dobre światło, całą sylwetkę w kadrze.',
      );
    }

    final span = (rawSamples.last.t - rawSamples.first.t).clamp(0.001, double.infinity);
    final fps = rawSamples.length / span;
    final smooth = smoothSamplesForFps(rawSamples, fps: fps);

    return BarbellAnalysisResult(
      samples: smooth,
      framesAnalyzed: framesAnalyzed,
      framesWithPose: framesWithPose,
    );
  }

  static Future<ui.Size?> _decodeSize(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final img = frame.image;
      final size = ui.Size(img.width.toDouble(), img.height.toDouble());
      img.dispose();
      return size;
    } catch (_) {
      return null;
    }
  }

  static BarbellSample? _sampleFromPose(
    Pose pose,
    double t,
    double width,
    double height,
  ) {
    double? nx(PoseLandmark? lm) {
      if (lm == null || lm.likelihood < _minLikelihood) return null;
      return (lm.x / width).clamp(0.0, 1.0);
    }

    double? ny(PoseLandmark? lm) {
      if (lm == null || lm.likelihood < _minLikelihood) return null;
      return (lm.y / height).clamp(0.0, 1.0);
    }

    double? midX(PoseLandmark? a, PoseLandmark? b) {
      final ax = nx(a);
      final bx = nx(b);
      if (ax != null && bx != null) return (ax + bx) / 2;
      return ax ?? bx;
    }

    double? midY(PoseLandmark? a, PoseLandmark? b) {
      final ay = ny(a);
      final by = ny(b);
      if (ay != null && by != null) return (ay + by) / 2;
      return ay ?? by;
    }

    final landmarks = pose.landmarks;
    final lw = landmarks[PoseLandmarkType.leftWrist];
    final rw = landmarks[PoseLandmarkType.rightWrist];
    final lh = landmarks[PoseLandmarkType.leftHip];
    final rh = landmarks[PoseLandmarkType.rightHip];
    final ls = landmarks[PoseLandmarkType.leftShoulder];
    final rs = landmarks[PoseLandmarkType.rightShoulder];
    final le = landmarks[PoseLandmarkType.leftElbow];
    final re = landmarks[PoseLandmarkType.rightElbow];

    final barX = midX(lw, rw);
    final barY = midY(lw, rw);
    final hipMidX = midX(lh, rh);
    final shoulderMidX = midX(ls, rs);

    if (barX == null || barY == null || hipMidX == null) {
      // Fallback: łokcie gdy nadgarstki niewidoczne
      final elbowX = midX(le, re);
      final elbowY = midY(le, re);
      if (elbowX == null || elbowY == null || hipMidX == null) {
        return null;
      }
      return BarbellSample(
        t: t,
        barX: elbowX,
        barY: elbowY,
        hipMidX: hipMidX,
        shoulderMidX: shoulderMidX ?? hipMidX,
      );
    }

    return BarbellSample(
      t: t,
      barX: barX,
      barY: barY,
      hipMidX: hipMidX,
      shoulderMidX: shoulderMidX ?? hipMidX,
    );
  }
}
