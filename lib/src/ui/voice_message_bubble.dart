import 'package:flutter/material.dart';

import '../logic/playback/voice_message_player.dart';
import '../logic/playback/voice_playback_event.dart';
import '../utils/duration_format.dart';
import '../utils/waveform_utils.dart';
import 'voice_message_scope.dart';
import 'waveform_painter.dart';

/// Chat-style bubble for playing a recorded voice message with a waveform.
@immutable
class VoiceMessageBubble extends StatefulWidget {
  const VoiceMessageBubble({
    super.key,
    required this.messageId,
    required this.audioPath,
    required this.duration,
    required this.waveform,
    this.player,
    this.isSent = false,
    this.backgroundColor,
    this.foregroundColor,
    this.progressColor,
    this.waveformBarCount = 32,
    this.onPlay,
    this.onStop,
    this.onPlaybackEvent,
  });

  final String messageId;
  final String audioPath;
  final Duration duration;
  final List<double> waveform;
  final VoiceMessagePlayer? player;
  final bool isSent;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? progressColor;
  final int waveformBarCount;
  final VoidCallback? onPlay;
  final VoidCallback? onStop;
  final void Function(VoicePlaybackEvent event)? onPlaybackEvent;

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  VoiceMessagePlayer? _player;
  List<double> _normalizedWaveform = const [];

  @override
  void initState() {
    super.initState();
    _cacheWaveform();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final resolvedPlayer = _resolvePlayer();
    if (!identical(_player, resolvedPlayer)) {
      _player?.removePlaybackEventListener(_handlePlaybackEvent);
      _player?.detach();
      _player = resolvedPlayer
        ..attach()
        ..addPlaybackEventListener(_handlePlaybackEvent);
    }
  }

  @override
  void didUpdateWidget(covariant VoiceMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.waveform != widget.waveform ||
        oldWidget.waveformBarCount != widget.waveformBarCount) {
      _cacheWaveform();
    }
  }

  @override
  void dispose() {
    _player?.removePlaybackEventListener(_handlePlaybackEvent);
    _player?.detach();
    super.dispose();
  }

  VoiceMessagePlayer _resolvePlayer() {
    return widget.player ??
        VoiceMessageScope.maybePlayerOf(context) ??
        VoiceMessagePlayer.instance;
  }

  void _cacheWaveform() {
    _normalizedWaveform = WaveformUtils.normalizeList(
      WaveformUtils.reduceList(widget.waveform, widget.waveformBarCount),
    );
  }

  void _handlePlaybackEvent(VoicePlaybackEvent event) {
    if (event.messageId != widget.messageId) {
      return;
    }

    widget.onPlaybackEvent?.call(event);
    switch (event) {
      case VoicePlaybackStarted():
        widget.onPlay?.call();
      case VoicePlaybackPaused():
      case VoicePlaybackStopped():
      case VoicePlaybackCompleted():
        widget.onStop?.call();
    }
  }

  Future<void> _onTogglePressed() async {
    final player = _player;
    if (player == null) {
      return;
    }

    try {
      await player.toggle(
        messageId: widget.messageId,
        source: widget.audioPath,
      );
    } on Object catch (error) {
      debugPrint('VoiceMessageBubble playback failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = _player ?? _resolvePlayer();
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

    return ListenableBuilder(
      listenable: player,
      builder: (context, _) {
        final isActive = player.isActive(widget.messageId);
        if (!isActive) {
          return _VoiceMessageBubbleContent(
            isSent: widget.isSent,
            background: background,
            foreground: foreground,
            progress: progress,
            waveform: _normalizedWaveform,
            isPlaying: false,
            progressValue: 0,
            remaining: widget.duration,
            onTogglePressed: _onTogglePressed,
          );
        }

        return ValueListenableBuilder<Duration>(
          valueListenable: player.positionNotifier,
          builder: (context, _, __) {
            final isPlaying = player.isPlaying;
            final progressValue = player.progressFor(widget.messageId);
            final labelDuration = player.duration > Duration.zero
                ? player.duration
                : widget.duration;
            final remainingMs = isPlaying
                ? (labelDuration.inMilliseconds -
                        player.position.inMilliseconds)
                    .clamp(0, labelDuration.inMilliseconds)
                : widget.duration.inMilliseconds;

            return _VoiceMessageBubbleContent(
              isSent: widget.isSent,
              background: background,
              foreground: foreground,
              progress: progress,
              waveform: _normalizedWaveform,
              isPlaying: isPlaying,
              progressValue: progressValue,
              remaining: Duration(milliseconds: remainingMs),
              onTogglePressed: _onTogglePressed,
            );
          },
        );
      },
    );
  }
}

@immutable
class _VoiceMessageBubbleContent extends StatelessWidget {
  const _VoiceMessageBubbleContent({
    required this.isSent,
    required this.background,
    required this.foreground,
    required this.progress,
    required this.waveform,
    required this.isPlaying,
    required this.progressValue,
    required this.remaining,
    required this.onTogglePressed,
  });

  final bool isSent;
  final Color background;
  final Color foreground;
  final Color progress;
  final List<double> waveform;
  final bool isPlaying;
  final double progressValue;
  final Duration remaining;
  final Future<void> Function() onTogglePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
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
                  constraints:
                      const BoxConstraints.tightFor(width: 36, height: 36),
                  onPressed: () => onTogglePressed(),
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
                  style:
                      theme.textTheme.labelMedium?.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
