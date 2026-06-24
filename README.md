# flutter_voice_message_ui

Minimal Flutter package for chat-style voice messages with waveform bars, single active playback, and recording UI.

## Features

- `VoiceMessageScope` + `VoiceMessagePlayer` — one active message per chat screen
- `VoiceMessageBubble` — play/stop control, duration label, bar waveform (`CustomPaint`)
- `VoicePlaybackEvent` — typed playback lifecycle callbacks (start, pause, stop, complete)
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

Wrap your chat screen with a shared player:

```dart
VoiceMessageScope(
  child: ListView(
    children: [
      VoiceMessageBubble(
        messageId: 'msg-1',
        audioPath: '/path/to/voice.m4a',
        duration: const Duration(seconds: 12),
        waveform: samples,
        isSent: true,
        onPlaybackEvent: (event) {
          // VoicePlaybackStarted, VoicePlaybackPaused, etc.
        },
      ),
    ],
  ),
);
```

Recording:

```dart
final controller = VoiceRecordController();
VoiceMessageRecorder(
  controller: controller,
  onRecordingComplete: (path, duration) {
    // Add the new message to your chat list.
  },
  onError: (error, stackTrace) {
    // Handle permission or recorder failures in your app.
  },
);
```

## Waveform data

This package renders waveform samples you provide. It does not extract amplitudes from audio files. For production apps, generate samples with a dedicated library (for example `audio_waveforms`, `ffmpeg`, or platform-specific APIs) and pass the normalized values to `VoiceMessageBubble`.

## Platform notes

- Microphone permission is required for recording (`NSMicrophoneUsageDescription` on iOS, `RECORD_AUDIO` on Android).
- Playback uses `just_audio` with local file paths.
