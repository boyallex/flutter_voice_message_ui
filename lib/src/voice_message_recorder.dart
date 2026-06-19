import 'package:flutter/material.dart';

import 'duration_format.dart';
import 'voice_record_controller.dart';

/// Compact recorder UI with record, pause, resume, send, and cancel actions.
class VoiceMessageRecorder extends StatefulWidget {
  const VoiceMessageRecorder({
    super.key,
    required this.controller,
    this.onRecordingComplete,
    this.onCancel,
    this.hintText = 'Hold to record a voice message',
  });

  final VoiceRecordController controller;
  final void Function(String filePath, Duration duration)? onRecordingComplete;
  final VoidCallback? onCancel;
  final String hintText;

  @override
  State<VoiceMessageRecorder> createState() => _VoiceMessageRecorderState();
}

class _VoiceMessageRecorderState extends State<VoiceMessageRecorder> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _startRecording() async {
    try {
      await widget.controller.start();
    } on StateError catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _sendRecording() async {
    final duration = widget.controller.elapsed;
    final path = await widget.controller.stop();
    if (path != null) {
      widget.onRecordingComplete?.call(path, duration);
    }
  }

  Future<void> _cancelRecording() async {
    await widget.controller.cancel();
    widget.onCancel?.call();
  }

  @override
  Widget build(BuildContext context) {
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
                tooltip: 'Record',
                onPressed: _startRecording,
                icon: const Icon(Icons.fiber_manual_record_rounded),
              )
            else ...[
              if (isRecording)
                IconButton(
                  tooltip: 'Pause',
                  onPressed: controller.pause,
                  icon: const Icon(Icons.pause_rounded),
                )
              else
                IconButton(
                  tooltip: 'Resume',
                  onPressed: controller.resume,
                  icon: const Icon(Icons.play_arrow_rounded),
                ),
              IconButton(
                tooltip: 'Send',
                onPressed: _sendRecording,
                icon: const Icon(Icons.send_rounded),
              ),
              IconButton(
                tooltip: 'Cancel',
                onPressed: _cancelRecording,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
