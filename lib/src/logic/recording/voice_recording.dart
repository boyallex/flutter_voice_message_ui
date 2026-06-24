import 'voice_record_controller.dart';
import '../storage/voice_message_storage.dart';
import 'voice_recorder.dart';

/// Entry point for voice message recording logic.
class VoiceRecording {
  VoiceRecording({
    required VoiceMessageStorage storage,
    VoiceRecorder? recorder,
    this.onRecordingSaved,
  }) : controller = VoiceRecordController(
          storage: storage,
          recorder: recorder,
        );

  final VoiceRecordController controller;
  final VoiceRecordingSaver? onRecordingSaved;

  /// Stops the active recording and invokes [onRecordingSaved] when a file exists.
  Future<VoiceRecordingResult?> send() async {
    final duration = controller.elapsed;
    final path = await controller.stop();
    if (path == null) {
      return null;
    }

    final result = VoiceRecordingResult(
      filePath: path,
      duration: duration,
    );
    await onRecordingSaved?.call(result);
    return result;
  }

  Future<void> cancel() => controller.cancel();

  void dispose() => controller.dispose();
}
