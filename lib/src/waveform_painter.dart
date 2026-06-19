import 'package:flutter/material.dart';

/// Paints a simple bar waveform with optional playback progress highlight.
class WaveformPainter extends CustomPainter {
  WaveformPainter({
    required this.samples,
    required this.color,
    required this.progressColor,
    required this.progress,
    this.barWidth = 3,
    this.barSpacing = 2,
    this.minBarHeight = 2,
  });

  final List<double> samples;
  final Color color;
  final Color progressColor;
  final double progress;
  final double barWidth;
  final double barSpacing;
  final double minBarHeight;

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty || size.width <= 0 || size.height <= 0) {
      return;
    }

    final barSlot = barWidth + barSpacing;
    final visibleBars = (size.width / barSlot).floor().clamp(1, samples.length);
    final normalizedSamples = samples.length == visibleBars
        ? samples
        : _pickSamples(visibleBars);

    final progressIndex = (progress.clamp(0, 1) * normalizedSamples.length)
        .floor()
        .clamp(0, normalizedSamples.length);

    for (var i = 0; i < normalizedSamples.length; i++) {
      final x = i * barSlot;
      final amplitude = normalizedSamples[i].clamp(0.0, 1.0);
      final barHeight =
          (amplitude * size.height).clamp(minBarHeight, size.height);
      final top = (size.height - barHeight) / 2;

      final paint = Paint()
        ..color = i < progressIndex ? progressColor : color
        ..strokeCap = StrokeCap.round
        ..strokeWidth = barWidth;

      canvas.drawLine(
        Offset(x + barWidth / 2, top),
        Offset(x + barWidth / 2, top + barHeight),
        paint,
      );
    }
  }

  List<double> _pickSamples(int count) {
    if (count <= 0) {
      return const [];
    }
    if (samples.length <= count) {
      return samples;
    }

    final step = samples.length / count;
    final picked = <double>[];
    for (var i = 0; i < count; i++) {
      final index = (i * step).floor().clamp(0, samples.length - 1);
      picked.add(samples[index]);
    }
    return picked;
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.samples != samples ||
        oldDelegate.color != color ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.progress != progress ||
        oldDelegate.barWidth != barWidth ||
        oldDelegate.barSpacing != barSpacing ||
        oldDelegate.minBarHeight != minBarHeight;
  }
}
