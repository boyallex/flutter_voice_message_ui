/// Result of a completed voice recording ready to be persisted by the host app.
class VoiceRecordingResult {
  const VoiceRecordingResult({
    required this.filePath,
    required this.duration,
  });

  final String filePath;
  final Duration duration;
}

/// Host-provided file operations for voice message recording.
abstract class VoiceMessageStorage {
  /// Returns a file path where a new recording should be written.
  Future<String> createRecordingPath();

  /// Removes the file at [path], for example when a recording is cancelled.
  Future<void> deleteFile(String path);
}

typedef VoiceRecordingPathFactory = Future<String> Function();
typedef VoiceFileDeleter = Future<void> Function(String path);
typedef VoiceRecordingSaver = Future<void> Function(VoiceRecordingResult result);

/// Function-based [VoiceMessageStorage] for simple integrations.
class VoiceMessageStorageCallbacks implements VoiceMessageStorage {
  const VoiceMessageStorageCallbacks({
    required VoiceRecordingPathFactory createRecordingPath,
    required VoiceFileDeleter deleteFile,
  })  : _createRecordingPath = createRecordingPath,
        _deleteFile = deleteFile;

  final VoiceRecordingPathFactory _createRecordingPath;
  final VoiceFileDeleter _deleteFile;

  @override
  Future<String> createRecordingPath() => _createRecordingPath();

  @override
  Future<void> deleteFile(String path) => _deleteFile(path);
}
