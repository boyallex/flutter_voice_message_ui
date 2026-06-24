import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_voice_message_ui/voice_recording.dart';
import 'package:record/record.dart';

class _InMemoryStorage implements VoiceMessageStorage {
  _InMemoryStorage(this.directoryPath);

  final String directoryPath;
  final deletedPaths = <String>[];

  @override
  Future<String> createRecordingPath() async {
    return '$directoryPath/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
  }

  @override
  Future<void> deleteFile(String path) async {
    deletedPaths.add(path);
  }
}

class _MockVoiceRecorder implements VoiceRecorder {
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
    late _MockVoiceRecorder recorder;
    late _InMemoryStorage storage;
    late VoiceRecordController controller;

    setUp(() {
      recorder = _MockVoiceRecorder();
      storage = _InMemoryStorage('/tmp');
      controller = VoiceRecordController(
        storage: storage,
        recorder: recorder,
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
      expect(storage.deletedPaths, isNotEmpty);
    });

    test('dispose cancels active recording', () async {
      await controller.start();
      controller.dispose();
      await Future<void>.delayed(Duration.zero);

      expect(recorder.lastKnownState, VoiceRecordState.idle);
      expect(recorder.disposed, isTrue);
    });

    test('parallel start calls are ignored while starting', () async {
      final slowRecorder = _SlowMockVoiceRecorder();
      final slowController = VoiceRecordController(
        storage: storage,
        recorder: slowRecorder,
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

  group('VoiceRecording', () {
    test('send invokes onRecordingSaved', () async {
      final storage = _InMemoryStorage('/tmp');
      final recorder = _MockVoiceRecorder();
      VoiceRecordingResult? saved;

      final recording = VoiceRecording(
        storage: storage,
        recorder: recorder,
        onRecordingSaved: (result) async {
          saved = result;
        },
      );

      await recording.controller.start();
      final result = await recording.send();

      expect(result, isNotNull);
      expect(saved, equals(result));
      recording.dispose();
    });
  });
}

class _SlowMockVoiceRecorder extends _MockVoiceRecorder {
  @override
  Future<bool> hasPermission() async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return permissionGranted;
  }
}
