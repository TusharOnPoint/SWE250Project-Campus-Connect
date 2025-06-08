import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class FilePickerWidget extends StatefulWidget {
  final Function(dynamic, String?) onFilePicked;

  FilePickerWidget({required this.onFilePicked});

  @override
  _FilePickerWidgetState createState() => _FilePickerWidgetState();
}

class _FilePickerWidgetState extends State<FilePickerWidget> {
  dynamic _pickedFile; // File for mobile, Uint8List for web
  String? _fileType;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.media);
      if (result != null) {
        setState(() {
          _fileType = result.files.single.extension == 'mp4' ? 'video' : 'image';

          if (kIsWeb) {
            // Use Uint8List for web
            _pickedFile = result.files.single.bytes;
          } else {
            // Use File for other platforms
            _pickedFile = File(result.files.single.path!);
          }
        });
        widget.onFilePicked(_pickedFile, _fileType);
      }
    } catch (e) {
      print("Error picking file: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking file')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _pickFile,
          icon: Icon(Icons.attach_file),
          label: Text("Pick File"),
        ),
        if (_pickedFile != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _fileType == 'image'
                ? kIsWeb
                ? Image.memory(_pickedFile, height: 200) // Use Image.memory for web
                : Image.file(_pickedFile, height: 200) // Use Image.file for mobile
                : Icon(Icons.video_file, size: 100),
          ),
      ],
    );
  }
}
