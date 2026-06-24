import 'package:record/record.dart';

/// Abstraction over microphone capture for testability.
abstract class VoiceRecorder {
  Future<bool> hasPermission();

  Future<void> start({
    required RecordConfig config,
    required String path,
  });

  Future<void> pause();

  Future<void> resume();

  Future<String?> stop();

  Future<void> dispose();
}

/// Default [VoiceRecorder] backed by the `record` package.
class RecordPackageRecorder implements VoiceRecorder {
  RecordPackageRecorder([AudioRecorder? recorder])
      : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<void> start({
    required RecordConfig config,
    required String path,
  }) =>
      _recorder.start(config, path: path);

  @override
  Future<void> pause() => _recorder.pause();

  @override
  Future<void> resume() => _recorder.resume();

  @override
  Future<String?> stop() => _recorder.stop();

  @override
  Future<void> dispose() => _recorder.dispose();
}
