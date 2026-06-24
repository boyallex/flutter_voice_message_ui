import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_voice_message_ui/flutter_voice_message_ui.dart';
import 'package:record/record.dart';

class _FakeVoiceRecorder implements VoiceRecorder {
  bool permissionGranted = true;
  bool disposed = false;
  int startCount = 0;
  String? startedPath;
  RecordConfig? startedConfig;
  VoiceRecordState lastKnownState = VoiceRecordState.idle;

  @override
  Future<bool> hasPermission() async => permissionGranted;

  @override
  Future<void> start({
    required RecordConfig config,
    required String path,
  }) async {
    startCount++;
    startedConfig = config;
    startedPath = path;
    lastKnownState = VoiceRecordState.recording;
  }

  @override
  Future<void> pause() async {
    lastKnownState = VoiceRecordState.paused;
  }

  @override
  Future<void> resume() async {
    lastKnownState = VoiceRecordState.recording;
  }

  @override
  Future<String?> stop() async {
    lastKnownState = VoiceRecordState.idle;
    return startedPath;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

void main() {
  group('VoiceRecordController', () {
    late _FakeVoiceRecorder recorder;
    late VoiceRecordController controller;

    setUp(() {
      recorder = _FakeVoiceRecorder();
      controller = VoiceRecordController(
        recorder: recorder,
        tempDirectoryPath: () async => '/tmp',
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('start records to a temp file when permission is granted', () async {
      await controller.start();

      expect(controller.state, VoiceRecordState.recording);
      expect(controller.filePath, startsWith('/tmp/voice_'));
      expect(recorder.startedPath, controller.filePath);
    });

    test('start throws when permission is denied', () async {
      recorder.permissionGranted = false;

      await expectLater(controller.start(), throwsA(isA<StateError>()));
      expect(controller.state, VoiceRecordState.idle);
    });

    test('pause and resume update state', () async {
      await controller.start();
      await controller.pause();
      expect(controller.state, VoiceRecordState.paused);

      await controller.resume();
      expect(controller.state, VoiceRecordState.recording);
    });

    test('cancel deletes active recording state', () async {
      await controller.start();
      await controller.cancel();

      expect(controller.state, VoiceRecordState.idle);
      expect(controller.filePath, isNull);
      expect(controller.elapsed, Duration.zero);
    });

    test('dispose cancels active recording', () async {
      await controller.start();
      controller.dispose();
      await Future<void>.delayed(Duration.zero);

      expect(recorder.lastKnownState, VoiceRecordState.idle);
      expect(recorder.disposed, isTrue);
    });

    test('parallel start calls are ignored while starting', () async {
      final slowRecorder = _SlowFakeVoiceRecorder();
      final slowController = VoiceRecordController(
        recorder: slowRecorder,
        tempDirectoryPath: () async => '/tmp',
      );

      final first = slowController.start();
      await Future<void>.delayed(Duration.zero);
      final second = slowController.start();

      await Future.wait([first, second]);
      expect(slowRecorder.startCount, 1);

      slowController.dispose();
      await Future<void>.delayed(Duration.zero);
    });
  });
}

class _SlowFakeVoiceRecorder extends _FakeVoiceRecorder {
  @override
  Future<bool> hasPermission() async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return permissionGranted;
  }
}
