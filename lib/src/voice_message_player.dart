import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Singleton audio controller that keeps only one voice message playing.
class VoiceMessagePlayer extends ChangeNotifier {
  VoiceMessagePlayer._();

  static final VoiceMessagePlayer instance = VoiceMessagePlayer._();

  final AudioPlayer _player = AudioPlayer();
  String? _activeMessageId;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _stateSub;

  String? get activeMessageId => _activeMessageId;
  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;
  bool get isPlaying => _player.playing;

  bool isActive(String messageId) => _activeMessageId == messageId;

  double progressFor(String messageId) {
    if (_activeMessageId != messageId) {
      return 0;
    }
    final total = duration.inMilliseconds;
    if (total <= 0) {
      return 0;
    }
    return position.inMilliseconds / total;
  }

  Future<void> play({
    required String messageId,
    required String source,
  }) async {
    if (_activeMessageId != messageId) {
      await _player.stop();
      await _player.setFilePath(source);
      _activeMessageId = messageId;
    }

    if (_player.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero);
    }

    await _player.play();
    notifyListeners();
  }

  Future<void> pause() async {
    await _player.pause();
    notifyListeners();
  }

  Future<void> stop() async {
    await _player.stop();
    _activeMessageId = null;
    notifyListeners();
  }

  Future<void> toggle({
    required String messageId,
    required String source,
  }) async {
    if (isActive(messageId) && isPlaying) {
      await pause();
      return;
    }

    if (isActive(messageId) && !isPlaying && position > Duration.zero) {
      await _player.play();
      notifyListeners();
      return;
    }

    await play(messageId: messageId, source: source);
  }

  void attach() {
    _positionSub ??= _player.positionStream.listen((_) => notifyListeners());
    _stateSub ??= _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _activeMessageId = null;
      }
      notifyListeners();
    });
  }

  void detach() {
    _positionSub?.cancel();
    _positionSub = null;
    _stateSub?.cancel();
    _stateSub = null;
  }

  @override
  void dispose() {
    detach();
    _player.dispose();
    super.dispose();
  }
}
