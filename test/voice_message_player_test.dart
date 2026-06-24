import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_voice_message_ui/flutter_voice_message_ui.dart';

void main() {
  group('VoiceMessagePlayer', () {
    test('progressFor returns 0 for inactive messages', () {
      final player = VoiceMessagePlayer();

      expect(player.progressFor('message-a'), 0);
    });

    test('attach and detach use reference counting', () {
      final player = VoiceMessagePlayer();

      player.attach();
      expect(player.isAttached, isTrue);

      player.attach();
      player.detach();
      expect(player.isAttached, isTrue);

      player.detach();
      expect(player.isAttached, isFalse);
    });

    test('isActive reflects the active message id', () {
      final player = VoiceMessagePlayer();

      expect(player.isActive('message-a'), isFalse);
      expect(player.activeMessageId, isNull);
    });

    test('playback listeners can be added and removed', () {
      final player = VoiceMessagePlayer();
      final events = <VoicePlaybackEvent>[];

      void listener(VoicePlaybackEvent event) => events.add(event);

      player.addPlaybackEventListener(listener);
      player.removePlaybackEventListener(listener);

      expect(events, isEmpty);
    });
  });
}
