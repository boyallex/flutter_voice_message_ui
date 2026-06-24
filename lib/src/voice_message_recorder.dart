import 'package:flutter/material.dart';

import 'duration_format.dart';
import 'recording/voice_record_controller.dart';

/// Compact recorder UI with record, pause, resume, send, and cancel actions.
@immutable
class VoiceMessageRecorder extends StatefulWidget {
  const VoiceMessageRecorder({
    super.key,
    required this.controller,
    this.onRecordingComplete,
    this.onCancel,
    this.onError,
    this.hintText = 'Hold to record a voice message',
    this.recordTooltip = 'Record',
    this.pauseTooltip = 'Pause',
    this.resumeTooltip = 'Resume',
    this.sendTooltip = 'Send',
    this.cancelTooltip = 'Cancel',
  });

  final VoiceRecordController controller;
  final void Function(String filePath, Duration duration)? onRecordingComplete;
  final VoidCallback? onCancel;
  final void Function(Object error, StackTrace stackTrace)? onError;
  final String hintText;
  final String recordTooltip;
  final String pauseTooltip;
  final String resumeTooltip;
  final String sendTooltip;
  final String cancelTooltip;

  @override
  State<VoiceMessageRecorder> createState() => _VoiceMessageRecorderState();
}

class _VoiceMessageRecorderState extends State<VoiceMessageRecorder> {
  Future<void> _startRecording() async {
    try {
      await widget.controller.start();
    } on Object catch (error, stackTrace) {
      widget.onError?.call(error, stackTrace);
    }
  }

  Future<void> _sendRecording() async {
    try {
      final duration = widget.controller.elapsed;
      final path = await widget.controller.stop();
      if (path != null) {
        widget.onRecordingComplete?.call(path, duration);
      }
    } on Object catch (error, stackTrace) {
      widget.onError?.call(error, stackTrace);
    }
  }

  Future<void> _cancelRecording() async {
    try {
      await widget.controller.cancel();
      widget.onCancel?.call();
    } on Object catch (error, stackTrace) {
      widget.onError?.call(error, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final theme = Theme.of(context);
        final isRecording = controller.state == VoiceRecordState.recording;
        final isPaused = controller.state == VoiceRecordState.paused;
        final isActive = isRecording || isPaused;

        return Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isActive ? Icons.mic_rounded : Icons.mic_none_rounded,
                  color: isRecording
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isActive
                        ? formatVoiceDuration(controller.elapsed)
                        : widget.hintText,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                if (!isActive)
                  IconButton(
                    tooltip: widget.recordTooltip,
                    onPressed: _startRecording,
                    icon: const Icon(Icons.fiber_manual_record_rounded),
                  )
                else ...[
                  if (isRecording)
                    IconButton(
                      tooltip: widget.pauseTooltip,
                      onPressed: controller.pause,
                      icon: const Icon(Icons.pause_rounded),
                    )
                  else
                    IconButton(
                      tooltip: widget.resumeTooltip,
                      onPressed: controller.resume,
                      icon: const Icon(Icons.play_arrow_rounded),
                    ),
                  IconButton(
                    tooltip: widget.sendTooltip,
                    onPressed: _sendRecording,
                    icon: const Icon(Icons.send_rounded),
                  ),
                  IconButton(
                    tooltip: widget.cancelTooltip,
                    onPressed: _cancelRecording,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
