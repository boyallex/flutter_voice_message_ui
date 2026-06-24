import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_voice_message_ui/voice_playback.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VoiceMessagePlayer', () {
    late VoiceMessagePlayer player;

    setUp(() {
      player = VoiceMessagePlayer();
    });

    tearDown(() {
      player.dispose();
    });

    test('progressFor returns 0 for inactive messages', () {
      expect(player.progressFor('message-a'), 0);
    });

    test('attach and detach use reference counting', () {
      player.attach();
      expect(player.isAttached, isTrue);

      player.attach();
      player.detach();
      expect(player.isAttached, isTrue);

      player.detach();
      expect(player.isAttached, isFalse);
    });

    test('isActive reflects the active message id', () {
      expect(player.isActive('message-a'), isFalse);
      expect(player.activeMessageId, isNull);
    });

    test('playback listeners can be added and removed', () {
      final events = <VoicePlaybackEvent>[];

      void listener(VoicePlaybackEvent event) => events.add(event);

      player.addPlaybackEventListener(listener);
      player.removePlaybackEventListener(listener);

      expect(events, isEmpty);
    });
  });

  group('VoicePlayback', () {
    test('owns and disposes a default player', () {
      final playback = VoicePlayback();
      expect(playback.player, isA<VoiceMessagePlayer>());
      playback.dispose();
    });
  });
}
