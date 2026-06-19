import 'package:flutter/material.dart';

import 'duration_format.dart';
import 'voice_message_player.dart';
import 'waveform_painter.dart';
import 'waveform_utils.dart';

/// Chat-style bubble for playing a recorded voice message with a waveform.
class VoiceMessageBubble extends StatefulWidget {
  const VoiceMessageBubble({
    super.key,
    required this.messageId,
    required this.audioPath,
    required this.duration,
    required this.waveform,
    this.isSent = false,
    this.backgroundColor,
    this.foregroundColor,
    this.progressColor,
    this.waveformBarCount = 32,
    this.onPlay,
    this.onStop,
  });

  final String messageId;
  final String audioPath;
  final Duration duration;
  final List<double> waveform;
  final bool isSent;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? progressColor;
  final int waveformBarCount;
  final VoidCallback? onPlay;
  final VoidCallback? onStop;

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  final VoiceMessagePlayer _player = VoiceMessagePlayer.instance;

  @override
  void initState() {
    super.initState();
    _player.attach();
    _player.addListener(_onPlayerChanged);
  }

  @override
  void dispose() {
    _player.removeListener(_onPlayerChanged);
    super.dispose();
  }

  void _onPlayerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _onTogglePressed() async {
    final isActive = _player.isActive(widget.messageId);
    final wasPlaying = isActive && _player.isPlaying;

    await _player.toggle(
      messageId: widget.messageId,
      source: widget.audioPath,
    );

    if (wasPlaying) {
      widget.onStop?.call();
    } else {
      widget.onPlay?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = widget.backgroundColor ??
        (widget.isSent
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest);
    final foreground = widget.foregroundColor ??
        (widget.isSent
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurfaceVariant);
    final progress = widget.progressColor ?? theme.colorScheme.primary;

    final isActive = _player.isActive(widget.messageId);
    final isPlaying = isActive && _player.isPlaying;
    final progressValue = isActive ? _player.progressFor(widget.messageId) : 0.0;
    final labelDuration =
        isActive && _player.duration > Duration.zero ? _player.duration : widget.duration;
    final remainingMs = isActive && isPlaying
        ? (labelDuration.inMilliseconds - _player.position.inMilliseconds)
            .clamp(0, labelDuration.inMilliseconds)
        : widget.duration.inMilliseconds;
    final remaining = Duration(milliseconds: remainingMs);
    final waveform = WaveformUtils.normalizeList(
      WaveformUtils.reduceList(widget.waveform, widget.waveformBarCount),
    );

    return Align(
      alignment: widget.isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                  onPressed: _onTogglePressed,
                  icon: Icon(
                    isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    color: foreground,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 28,
                    child: CustomPaint(
                      painter: WaveformPainter(
                        samples: waveform,
                        color: foreground.withValues(alpha: 0.35),
                        progressColor: progress,
                        progress: progressValue,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatVoiceDuration(remaining),
                  style: theme.textTheme.labelMedium?.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
