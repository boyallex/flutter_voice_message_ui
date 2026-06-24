import 'package:path_provider/path_provider.dart';

import '../../utils/file_deleter.dart';
import 'voice_message_storage.dart';

/// Default [VoiceMessageStorage] using the app temp directory.
class PlatformVoiceMessageStorage implements VoiceMessageStorage {
  const PlatformVoiceMessageStorage();

  @override
  Future<String> createRecordingPath() async {
    final directory = await getTemporaryDirectory();
    return '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
  }

  @override
  Future<void> deleteFile(String path) => deleteFileIfExists(path);
}
