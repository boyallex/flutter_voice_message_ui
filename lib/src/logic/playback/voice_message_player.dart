import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'voice_playback_event.dart';

typedef VoicePlaybackEventCallback = void Function(VoicePlaybackEvent event);

/// Audio controller that keeps only one voice message playing at a time.
class VoiceMessagePlayer extends ChangeNotifier {
  VoiceMessagePlayer({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  static VoiceMessagePlayer? _instance;

  /// Shared player for simple integrations. Prefer [VoicePlayback] via
  /// [VoiceMessageScope] in apps.
  static VoiceMessagePlayer get instance => _instance ??= VoiceMessagePlayer();

  final AudioPlayer _player;
  final ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);

  String? _activeMessageId;
  int _attachCount = 0;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _stateSub;
  final List<VoicePlaybackEventCallback> _eventListeners = [];
  void Function(VoicePlaybackEvent event)? onPlaybackEvent;

  String? get activeMessageId => _activeMessageId;
  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;
  bool get isPlaying => _player.playing;
  bool get isAttached => _attachCount > 0;

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
    try {
      final previousId = _activeMessageId;

      if (_activeMessageId != messageId) {
        if (previousId != null) {
          _emit(VoicePlaybackStopped(previousId));
        }
        await _player.stop();
        await _player.setFilePath(source);
        _activeMessageId = messageId;
      }

      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }

      await _player.play();
      _emit(VoicePlaybackStarted(messageId));
      _notifyStateChanged();
    } catch (error, stackTrace) {
      _activeMessageId = null;
      _notifyStateChanged();
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> pause() async {
    if (_activeMessageId == null) {
      return;
    }

    try {
      final messageId = _activeMessageId!;
      await _player.pause();
      _emit(VoicePlaybackPaused(messageId));
      _notifyStateChanged();
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> stop() async {
    final messageId = _activeMessageId;
    if (messageId == null) {
      return;
    }

    try {
      await _player.stop();
      _activeMessageId = null;
      _emit(VoicePlaybackStopped(messageId));
      _notifyStateChanged();
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
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
      try {
        await _player.play();
        _emit(VoicePlaybackStarted(messageId));
        _notifyStateChanged();
      } catch (error, stackTrace) {
        Error.throwWithStackTrace(error, stackTrace);
      }
      return;
    }

    await play(messageId: messageId, source: source);
  }

  void addPlaybackEventListener(VoicePlaybackEventCallback listener) {
    if (!_eventListeners.contains(listener)) {
      _eventListeners.add(listener);
    }
  }

  void removePlaybackEventListener(VoicePlaybackEventCallback listener) {
    _eventListeners.remove(listener);
  }

  void attach() {
    _attachCount++;
    if (_attachCount > 1) {
      return;
    }

    _positionSub = _player.positionStream.listen((position) {
      positionNotifier.value = position;
    });
    _stateSub = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed &&
          _activeMessageId != null) {
        final messageId = _activeMessageId!;
        _activeMessageId = null;
        _emit(VoicePlaybackCompleted(messageId));
        _notifyStateChanged();
      }
    });
  }

  void detach() {
    if (_attachCount == 0) {
      return;
    }

    _attachCount--;
    if (_attachCount > 0) {
      return;
    }

    _positionSub?.cancel();
    _positionSub = null;
    _stateSub?.cancel();
    _stateSub = null;
  }

  void _emit(VoicePlaybackEvent event) {
    onPlaybackEvent?.call(event);
    for (final listener in List<VoicePlaybackEventCallback>.of(_eventListeners)) {
      listener(event);
    }
  }

  void _notifyStateChanged() {
    positionNotifier.value = _player.position;
    notifyListeners();
  }

  @override
  void dispose() {
    detach();
    positionNotifier.dispose();
    _player.dispose();
    if (identical(_instance, this)) {
      _instance = null;
    }
    super.dispose();
  }
}
