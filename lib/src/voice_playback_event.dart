/// Playback lifecycle events emitted by [VoiceMessagePlayer].
sealed class VoicePlaybackEvent {
  const VoicePlaybackEvent(this.messageId);

  final String messageId;
}

/// Emitted when playback starts or resumes for [messageId].
final class VoicePlaybackStarted extends VoicePlaybackEvent {
  const VoicePlaybackStarted(super.messageId);
}

/// Emitted when playback is paused for [messageId].
final class VoicePlaybackPaused extends VoicePlaybackEvent {
  const VoicePlaybackPaused(super.messageId);
}

/// Emitted when playback stops before completion (switch or explicit stop).
final class VoicePlaybackStopped extends VoicePlaybackEvent {
  const VoicePlaybackStopped(super.messageId);
}

/// Emitted when playback reaches the end of the track.
final class VoicePlaybackCompleted extends VoicePlaybackEvent {
  const VoicePlaybackCompleted(super.messageId);
}
