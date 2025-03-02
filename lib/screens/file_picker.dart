import 'package:file_picker/file_picker.dart';

class FilePickerHelper {
  static Future<String?> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any, // Allows all file types
    );

    if (result != null && result.files.isNotEmpty) {
      return result.files.single.path; // Returns the selected file path
    }
    return null; // No file selected
  }
}
