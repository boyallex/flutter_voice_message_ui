import 'dart:io';

Future<void> deleteFileIfExists(String path) async {
  final file = File(path);
  if (file.existsSync()) {
    await file.delete();
  }
}
