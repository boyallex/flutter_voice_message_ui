# flutter_voice_message_ui

> **Design context.** This package was extracted from a production chat app. A few defaults (waveform supplied by the host, temp-file storage helper, shared player scope) are intentional trade-offs from that codebase, not oversights.

Minimal Flutter package for chat-style voice messages with waveform bars, single active playback, and recording UI.

## Package structure

```
lib/
  flutter_voice_message_ui.dart   # full export (UI + logic)
  voice_recording.dart            # recording entry point
  voice_playback.dart             # playback entry point
  src/
    logic/
      recording/                  # VoiceRecording, VoiceRecordController
      playback/                   # VoicePlayback, VoiceMessagePlayer
      storage/                    # VoiceMessageStorage (injectable)
    ui/                           # widgets
    utils/                        # formatters, waveform helpers
```

## Features

- `VoiceRecording` + `VoiceMessageStorage` — recording logic with injected file operations
- `VoicePlayback` + `VoiceMessageScope` — one active message per chat screen
- `VoiceMessageBubble` — play/stop control, duration label, bar waveform
- `VoicePlaybackEvent` — typed playback lifecycle callbacks
- `VoiceMessageRecorder` — record, pause, send, cancel UI

## Getting started

```yaml
dependencies:
  flutter_voice_message_ui: ^0.1.0
```

```dart
import 'package:flutter_voice_message_ui/flutter_voice_message_ui.dart';
```

Or import only the layer you need:

```dart
import 'package:flutter_voice_message_ui/voice_recording.dart';
import 'package:flutter_voice_message_ui/voice_playback.dart';
```

## Usage

### Storage (required for recording)

Inject how files are created and deleted:

```dart
final recording = VoiceRecording(
  storage: const PlatformVoiceMessageStorage(),
  onRecordingSaved: (result) async {
    await chatRepository.saveVoiceMessage(
      path: result.filePath,
      duration: result.duration,
    );
  },
);
```

Or provide callbacks directly:

```dart
final recording = VoiceRecording(
  storage: VoiceMessageStorageCallbacks(
    createRecordingPath: () async => '/tmp/voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
    deleteFile: (path) async => File(path).delete(),
  ),
);
```

### Playback

```dart
VoiceMessageScope(
  child: VoiceMessageBubble(
    messageId: 'msg-1',
    audioPath: '/path/to/voice.m4a',
    duration: const Duration(seconds: 12),
    waveform: samples,
    isSent: true,
  ),
);
```

### Recording UI

```dart
VoiceMessageRecorder(
  recording: recording,
  onRecordingComplete: (path, duration) {
    // Update local UI state after send.
  },
  onError: (error, stackTrace) { ... },
);
```

## Waveform data

This package renders waveform samples you provide. It does not extract amplitudes from audio files.

## Platform notes

- Microphone permission is required for recording.
- Playback uses `just_audio` with local file paths.
