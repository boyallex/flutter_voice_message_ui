import 'package:flutter/material.dart';

import 'voice_message_player.dart';

/// Provides a shared [VoiceMessagePlayer] to descendant widgets.
///
/// Wrap your chat screen so every [VoiceMessageBubble] shares one player
/// with reference-counted stream subscriptions.
@immutable
class VoiceMessageScope extends StatefulWidget {
  const VoiceMessageScope({
    super.key,
    required this.child,
    this.player,
  });

  final Widget child;
  final VoiceMessagePlayer? player;

  static VoiceMessagePlayer of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_InheritedVoiceMessageScope>();
    assert(scope != null, 'VoiceMessageScope not found in context');
    return scope!.player;
  }

  static VoiceMessagePlayer? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InheritedVoiceMessageScope>()
        ?.player;
  }

  @override
  State<VoiceMessageScope> createState() => _VoiceMessageScopeState();
}

class _VoiceMessageScopeState extends State<VoiceMessageScope> {
  late final VoiceMessagePlayer _player =
      widget.player ?? VoiceMessagePlayer();
  late final bool _ownsPlayer = widget.player == null;

  @override
  void dispose() {
    if (_ownsPlayer) {
      _player.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedVoiceMessageScope(
      player: _player,
      child: widget.child,
    );
  }
}

class _InheritedVoiceMessageScope extends InheritedWidget {
  const _InheritedVoiceMessageScope({
    required this.player,
    required super.child,
  });

  final VoiceMessagePlayer player;

  @override
  bool updateShouldNotify(_InheritedVoiceMessageScope oldWidget) {
    return player != oldWidget.player;
  }
}
