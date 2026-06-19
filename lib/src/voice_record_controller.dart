import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'file_deleter.dart';

/// Recording lifecycle for voice messages.
enum VoiceRecordState {
  idle,
  recording,
  paused,
}

/// Controller that wraps the [record] package for voice capture.
class VoiceRecordController extends ChangeNotifier {
  VoiceRecordController({AudioRecorder? recorder})
      : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  VoiceRecordState _state = VoiceRecordState.idle;
  Duration _elapsed = Duration.zero;
  String? _filePath;
  Timer? _timer;

  VoiceRecordState get state => _state;
  Duration get elapsed => _elapsed;
  String? get filePath => _filePath;
  bool get isRecording => _state == VoiceRecordState.recording;

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<void> start() async {
    if (_state == VoiceRecordState.recording) {
      return;
    }

    final granted = await hasPermission();
    if (!granted) {
      throw StateError('Microphone permission was not granted.');
    }

    final directory = await getTemporaryDirectory();
    _filePath =
        '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: _filePath!,
    );

    _state = VoiceRecordState.recording;
    _elapsed = Duration.zero;
    _startTimer();
    notifyListeners();
  }

  Future<void> pause() async {
    if (_state != VoiceRecordState.recording) {
      return;
    }

    await _recorder.pause();
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
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }
}
