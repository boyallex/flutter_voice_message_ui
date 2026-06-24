import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_voice_message_ui/flutter_voice_message_ui.dart';
import 'package:record/record.dart';

void main() {
  group('WaveformUtils', () {
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
  });

  group('formatVoiceDuration', () {
    test('renders m:ss', () {
      expect(formatVoiceDuration(const Duration(seconds: 65)), '1:05');
    });

    test('renders h:mm:ss for long durations', () {
      expect(
        formatVoiceDuration(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1:02:03',
      );
    });
  });

  group('VoiceMessagePlayer', () {
    test('attach and detach use reference counting', () {
      final player = VoiceMessagePlayer();

      player.attach();
      player.attach();
      expect(player.isAttached, isTrue);

      player.detach();
      expect(player.isAttached, isTrue);

      player.detach();
      expect(player.isAttached, isFalse);
    });

    test('progressFor returns zero for inactive messages', () {
      final player = VoiceMessagePlayer();

      expect(player.progressFor('msg-1'), 0);
    });

    test('registers playback event listeners', () {
      final player = VoiceMessagePlayer();
      final events = <VoicePlaybackEvent>[];

      void listener(VoicePlaybackEvent event) => events.add(event);

      player.addPlaybackEventListener(listener);
      player.removePlaybackEventListener(listener);

      expect(events, isEmpty);
    });
  });

  group('VoiceRecordController', () {
    test('start transitions to recording when permission is granted', () async {
      final recorder = _FakeVoiceRecorder();
      final controller = VoiceRecordController(
        recorder: recorder,
        tempDirectoryPath: () async => '/tmp',
      );

      await controller.start();

      expect(controller.state, VoiceRecordState.recording);
      expect(controller.filePath, isNotNull);
      expect(recorder.isRecording, isTrue);
    });

    test('start throws when permission is denied', () async {
      final recorder = _FakeVoiceRecorder(permissionGranted: false);
      final controller = VoiceRecordController(
        recorder: recorder,
        tempDirectoryPath: () async => '/tmp',
      );

      await expectLater(controller.start(), throwsA(isA<StateError>()));
      expect(controller.state, VoiceRecordState.idle);
    });

    test('parallel start calls only start once', () async {
      final recorder = _FakeVoiceRecorder();
      final controller = VoiceRecordController(
        recorder: recorder,
        tempDirectoryPath: () async => '/tmp',
      );

      await Future.wait([controller.start(), controller.start()]);

      expect(recorder.startCount, 1);
    });

    test('pause and resume update state', () async {
      final recorder = _FakeVoiceRecorder();
      final controller = VoiceRecordController(
        recorder: recorder,
        tempDirectoryPath: () async => '/tmp',
      );

      await controller.start();
      await controller.pause();
      expect(controller.state, VoiceRecordState.paused);

      await controller.resume();
      expect(controller.state, VoiceRecordState.recording);
    });

    test('dispose stops active recording', () async {
      final recorder = _FakeVoiceRecorder();
      final controller = VoiceRecordController(
        recorder: recorder,
        tempDirectoryPath: () async => '/tmp',
      );

      await controller.start();
      controller.dispose();

      expect(recorder.isRecording, isFalse);
      expect(recorder.disposeCount, 1);
    });
  });
}

class _FakeVoiceRecorder implements VoiceRecorder {
  _FakeVoiceRecorder({this.permissionGranted = true});

  final bool permissionGranted;
  bool isRecording = false;
  int startCount = 0;
  int disposeCount = 0;
  String? lastPath;

  @override
  Future<void> dispose() async {
    disposeCount++;
  }

  @override
  Future<bool> hasPermission() async => permissionGranted;

  @override
  Future<void> pause() async {
    isRecording = false;
  }

  @override
  Future<void> resume() async {
    isRecording = true;
  }

  @override
  Future<void> start({
    required RecordConfig config,
    required String path,
  }) async {
    startCount++;
    isRecording = true;
    lastPath = path;
  }

  @override
  Future<String?> stop() async {
    isRecording = false;
    return lastPath;
  }
}
