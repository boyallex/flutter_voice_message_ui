import 'package:flutter/material.dart';

import '../logic/playback/voice_playback.dart';
import '../logic/playback/voice_message_player.dart';

/// Provides shared [VoicePlayback] logic to descendant widgets.
@immutable
class VoiceMessageScope extends StatefulWidget {
  const VoiceMessageScope({
    super.key,
    required this.child,
    this.playback,
    this.player,
  });

  final Widget child;
  final VoicePlayback? playback;
  final VoiceMessagePlayer? player;

  static VoicePlayback of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_InheritedVoiceMessageScope>();
    assert(scope != null, 'VoiceMessageScope not found in context');
    return scope!.playback;
  }

  static VoicePlayback? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InheritedVoiceMessageScope>()
        ?.playback;
  }

  static VoiceMessagePlayer? maybePlayerOf(BuildContext context) {
    return maybeOf(context)?.player;
  }

  @override
  State<VoiceMessageScope> createState() => _VoiceMessageScopeState();
}

class _VoiceMessageScopeState extends State<VoiceMessageScope> {
  late final VoicePlayback _playback = widget.playback ??
      (widget.player != null
          ? VoicePlayback(player: widget.player)
          : VoicePlayback());
  late final bool _ownsPlayback =
      widget.playback == null && widget.player == null;

  @override
  void dispose() {
    if (_ownsPlayback) {
      _playback.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedVoiceMessageScope(
      playback: _playback,
      child: widget.child,
    );
  }
}

class _InheritedVoiceMessageScope extends InheritedWidget {
  const _InheritedVoiceMessageScope({
    required this.playback,
    required super.child,
  });

  final VoicePlayback playback;

  @override
  bool updateShouldNotify(_InheritedVoiceMessageScope oldWidget) {
    return playback != oldWidget.playback;
  }
}
