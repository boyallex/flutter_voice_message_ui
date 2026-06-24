import 'voice_message_player.dart';

/// Entry point for voice message playback logic.
class VoicePlayback {
  VoicePlayback({VoiceMessagePlayer? player})
      : _ownsPlayer = player == null,
        player = player ?? VoiceMessagePlayer();

  final bool _ownsPlayer;
  final VoiceMessagePlayer player;

  void dispose() {
    if (_ownsPlayer) {
      player.dispose();
    }
  }
}
