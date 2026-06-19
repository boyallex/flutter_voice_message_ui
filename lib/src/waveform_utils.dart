/// Utilities for downsampling and normalizing waveform amplitude samples.
class WaveformUtils {
  WaveformUtils._();

  /// Downsamples [samples] to [targetLength] bars using peak values per bucket.
  static List<double> reduceList(List<double> samples, int targetLength) {
    if (samples.isEmpty || targetLength <= 0) {
      return const [];
    }
    if (samples.length <= targetLength) {
      return List<double>.from(samples);
    }

    final bucketSize = samples.length / targetLength;
    final reduced = <double>[];

    for (var i = 0; i < targetLength; i++) {
      final start = (i * bucketSize).floor();
      final end = ((i + 1) * bucketSize).ceil().clamp(start + 1, samples.length);
      var peak = 0.0;
      for (var j = start; j < end; j++) {
        final value = samples[j].abs();
        if (value > peak) {
          peak = value;
        }
      }
      reduced.add(peak);
    }

    return reduced;
  }

  /// Scales [samples] so the largest absolute value becomes `1.0`.
  static List<double> normalizeList(List<double> samples) {
    if (samples.isEmpty) {
      return const [];
    }

    var maxValue = 0.0;
    for (final sample in samples) {
      final absValue = sample.abs();
      if (absValue > maxValue) {
        maxValue = absValue;
      }
    }

    if (maxValue == 0) {
      return List<double>.filled(samples.length, 0);
    }

    return samples.map((sample) => sample.abs() / maxValue).toList();
  }
}
