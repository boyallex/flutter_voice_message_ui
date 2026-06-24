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
    final normalizedSamples = visibleBars < samples.length
        ? samples.sublist(0, visibleBars)
        : samples;

    final progressIndex = (progress.clamp(0, 1) * normalizedSamples.length)
        .floor()
        .clamp(0, normalizedSamples.length);

    final inactivePaint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;
    final activePaint = Paint()
      ..color = progressColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;

    for (var i = 0; i < normalizedSamples.length; i++) {
      final x = i * barSlot;
      final amplitude = normalizedSamples[i].clamp(0.0, 1.0);
      final barHeight =
          (amplitude * size.height).clamp(minBarHeight, size.height);
      final top = (size.height - barHeight) / 2;
      final paint = i < progressIndex ? activePaint : inactivePaint;

      canvas.drawLine(
        Offset(x + barWidth / 2, top),
        Offset(x + barWidth / 2, top + barHeight),
        paint,
      );
    }
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
