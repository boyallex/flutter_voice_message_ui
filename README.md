# flutter_voice_message_ui

Minimal Flutter SDK for chat-style voice messages with waveform bars, single active playback, and recording UI.

## Features

- `VoiceMessagePlayer` — singleton controller; only one message plays at a time
- `VoiceMessageBubble` — play/stop control, duration label, bar waveform (`CustomPaint`)
- `WaveformUtils.reduceList` / `WaveformUtils.normalizeList` — downsample and normalize samples
- `VoiceRecordController` + `VoiceMessageRecorder` — record, pause, send, cancel via the `record` package

## Getting started

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter_voice_message_ui: ^0.1.0
```

Import:

```dart
import 'package:flutter_voice_message_ui/flutter_voice_message_ui.dart';
```

## Usage

```dart
VoiceMessageBubble(
  messageId: 'msg-1',
  audioPath: '/path/to/voice.m4a',
  duration: const Duration(seconds: 12),
  waveform: WaveformUtils.normalizeList(samples),
  isSent: true,
);

final controller = VoiceRecordController();
VoiceMessageRecorder(
  controller: controller,
  onRecordingComplete: (path, duration) {
    // Add the new message to your chat list.
  },
);
```

Run the bundled demo:

```bash
cd example
flutter run
```

## Platform notes

- Microphone permission is required for recording (`NSMicrophoneUsageDescription` on iOS, `RECORD_AUDIO` on Android).
- Playback uses `just_audio` with local file paths.

## License

MIT — see [LICENSE](LICENSE).
