import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../file_deleter.dart';
import 'voice_recorder.dart';

/// Recording lifecycle for voice messages.
enum VoiceRecordState {
  idle,
  recording,
  paused,
}

/// Controller that wraps a [VoiceRecorder] for voice capture.
class VoiceRecordController extends ChangeNotifier {
  VoiceRecordController({
    VoiceRecorder? recorder,
    Future<String> Function()? tempDirectoryPath,
  })  : _recorder = recorder ?? RecordPackageRecorder(),
        _tempDirectoryPath = tempDirectoryPath ?? _defaultTempDirectoryPath;

  final VoiceRecorder _recorder;
  final Future<String> Function() _tempDirectoryPath;
  VoiceRecordState _state = VoiceRecordState.idle;
  Duration _elapsed = Duration.zero;
  String? _filePath;
  Timer? _timer;
  bool _isStarting = false;
  DateTime? _recordingStartedAt;
  Duration _pausedElapsed = Duration.zero;

  VoiceRecordState get state => _state;
  Duration get elapsed => _elapsed;
  String? get filePath => _filePath;
  bool get isRecording => _state == VoiceRecordState.recording;

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<void> start() async {
    if (_state != VoiceRecordState.idle || _isStarting) {
      return;
    }

    _isStarting = true;
    try {
      final granted = await hasPermission();
      if (!granted) {
        throw StateError('Microphone permission was not granted.');
      }

      if (_state != VoiceRecordState.idle) {
        return;
      }

      final directoryPath = await _tempDirectoryPath();
      _filePath =
          '$directoryPath/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        config: const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _filePath!,
      );

      _state = VoiceRecordState.recording;
      _elapsed = Duration.zero;
      _pausedElapsed = Duration.zero;
      _recordingStartedAt = DateTime.now();
      _startTimer();
      notifyListeners();
    } finally {
      _isStarting = false;
    }
  }

  Future<void> pause() async {
    if (_state != VoiceRecordState.recording) {
      return;
    }

    await _recorder.pause();
    _pausedElapsed = _elapsed;
    _state = VoiceRecordState.paused;
    _timer?.cancel();
    notifyListeners();
  }

  Future<void> resume() async {
    if (_state != VoiceRecordState.paused) {
      return;
    }

    await _recorder.resume();
    _state = VoiceRecordState.recording;
    _recordingStartedAt = DateTime.now();
    _startTimer();
    notifyListeners();
  }

  Future<String?> stop() async {
    if (_state == VoiceRecordState.idle) {
      return null;
    }

    final path = await _recorder.stop();
    _state = VoiceRecordState.idle;
    _timer?.cancel();
    _syncElapsedFromClock();
    notifyListeners();
    return path ?? _filePath;
  }

  Future<void> cancel() async {
    final path = await stop();
    if (path != null) {
      await deleteFileIfExists(path);
    }
    _filePath = null;
    _elapsed = Duration.zero;
    _pausedElapsed = Duration.zero;
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      _syncElapsedFromClock();
      notifyListeners();
    });
  }

  void _syncElapsedFromClock() {
    final startedAt = _recordingStartedAt;
    if (_state == VoiceRecordState.recording && startedAt != null) {
      _elapsed = _pausedElapsed + DateTime.now().difference(startedAt);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_state != VoiceRecordState.idle) {
      unawaited(_cancelActiveRecording());
    }
    unawaited(_recorder.dispose());
    super.dispose();
  }

  Future<void> _cancelActiveRecording() async {
    try {
      final path = await _recorder.stop();
      _state = VoiceRecordState.idle;
      if (path != null) {
        await deleteFileIfExists(path);
      }
    } on Object {
      _state = VoiceRecordState.idle;
    }
    _filePath = null;
    _elapsed = Duration.zero;
    _pausedElapsed = Duration.zero;
  }

  static Future<String> _defaultTempDirectoryPath() async {
    final directory = await getTemporaryDirectory();
    return directory.path;
  }
}
