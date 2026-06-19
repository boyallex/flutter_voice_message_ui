import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_voice_message_ui/flutter_voice_message_ui.dart';

void main() {
  test('reduceList downsamples using peak values', () {
    final reduced = WaveformUtils.reduceList(
      [0.1, 0.9, 0.2, 0.8, 0.3, 0.7],
      3,
    );

    expect(reduced, [0.9, 0.8, 0.7]);
  });

  test('normalizeList scales samples to 0..1', () {
    final normalized = WaveformUtils.normalizeList([2, 4, 8]);

    expect(normalized, [0.25, 0.5, 1.0]);
  });

  test('formatVoiceDuration renders m:ss', () {
    expect(formatVoiceDuration(const Duration(seconds: 65)), '1:05');
  });
}
