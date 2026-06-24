import 'package:flutter/material.dart';

import '../logic/recording/voice_record_controller.dart';
import '../logic/recording/voice_recording.dart';
import '../utils/duration_format.dart';

/// Compact recorder UI with record, pause, resume, send, and cancel actions.
@immutable
class VoiceMessageRecorder extends StatelessWidget {
  const VoiceMessageRecorder({
    super.key,
    required this.recording,
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

  final VoiceRecording recording;
  final void Function(String filePath, Duration duration)? onRecordingComplete;
  final VoidCallback? onCancel;
  final void Function(Object error, StackTrace stackTrace)? onError;
  final String hintText;
  final String recordTooltip;
  final String pauseTooltip;
  final String resumeTooltip;
  final String sendTooltip;
  final String cancelTooltip;

  VoiceRecordController get _controller => recording.controller;

  Future<void> _startRecording() async {
    try {
      await _controller.start();
    } on Object catch (error, stackTrace) {
      onError?.call(error, stackTrace);
    }
  }

  Future<void> _sendRecording() async {
    try {
      final result = await recording.send();
      if (result != null) {
        onRecordingComplete?.call(result.filePath, result.duration);
      }
    } on Object catch (error, stackTrace) {
      onError?.call(error, stackTrace);
    }
  }

  Future<void> _cancelRecording() async {
    try {
      await recording.cancel();
      onCancel?.call();
    } on Object catch (error, stackTrace) {
      onError?.call(error, stackTrace);
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await _controller.pause();
    } on Object catch (error, stackTrace) {
      onError?.call(error, stackTrace);
    }
  }

  Future<void> _resumeRecording() async {
    try {
      await _controller.resume();
    } on Object catch (error, stackTrace) {
      onError?.call(error, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final controller = _controller;
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
                        : hintText,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                if (!isActive)
                  IconButton(
                    tooltip: recordTooltip,
                    onPressed: _startRecording,
                    icon: const Icon(Icons.fiber_manual_record_rounded),
                  )
                else ...[
                  if (isRecording)
                    IconButton(
                      tooltip: pauseTooltip,
                      onPressed: _pauseRecording,
                      icon: const Icon(Icons.pause_rounded),
                    )
                  else
                    IconButton(
                      tooltip: resumeTooltip,
                      onPressed: _resumeRecording,
                      icon: const Icon(Icons.play_arrow_rounded),
                    ),
                  IconButton(
                    tooltip: sendTooltip,
                    onPressed: _sendRecording,
                    icon: const Icon(Icons.send_rounded),
                  ),
                  IconButton(
                    tooltip: cancelTooltip,
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
