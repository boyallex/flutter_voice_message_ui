/// Formats a [Duration] as `m:ss` or `h:mm:ss` for voice message labels.
String formatVoiceDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  if (totalSeconds >= 3600) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
