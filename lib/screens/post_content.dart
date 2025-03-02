import 'package:flutter/material.dart';
import 'file_picker.dart'; // Ensure the correct import

class PostContentScreen extends StatefulWidget {
  @override
  _PostContentScreenState createState() => _PostContentScreenState();
}

class _PostContentScreenState extends State<PostContentScreen> {
  String? filePath;

  void selectFile() async {
    String? selectedFile = await FilePickerHelper.pickFile();
    if (selectedFile != null) {
      setState(() {
        filePath = selectedFile;
      });
      print("Selected File: $filePath");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Post Content")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: selectFile,
              child: Text("Pick a File"),
            ),
            if (filePath != null) ...[
              SizedBox(height: 20),
              Text("Selected File: $filePath"),
            ]
          ],
        ),
      ),
    );
  }
}
