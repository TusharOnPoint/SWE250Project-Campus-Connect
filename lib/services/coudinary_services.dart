import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<String?> uploadToCloudinary(FilePickerResult? filePickerResult, String fileType) async {
  if(filePickerResult == null || filePickerResult.files.isEmpty){
    print("no file selected");
    return null;
  }
  //File file = File(filePickerResult.files.single.path!);

  final fileBytes = filePickerResult.files.single.bytes;
  final fileName = filePickerResult.files.single.name;

  String cloudName = dotenv.env["CLOUDINARY_CLOUD_NAME"] ?? '';
  final resourceType = fileType == 'video' ? 'video' : 'image';

  final uri = Uri.parse(
    'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload',
  );
  var request = http.MultipartRequest("POST", uri);

  //var fileBytes = await file.readAsBytes();
  if (fileBytes == null) {
    print("File has no bytes");
    return null;
  }

  var multiPartFile = http.MultipartFile.fromBytes('file', fileBytes, filename: fileName);

  request.files.add(multiPartFile);
  request.fields["upload_preset"] = "campus_connect_tushar_sajib";
  //request.fields["resource_type"] = "raw";

  var response = await request.send();
  var responseBody = await response.stream.bytesToString();
  print('Cloudinary response: $responseBody');
  if(response.statusCode == 200){
    var responseJson = jsonDecode(responseBody);
    print("upload successful");
    return responseJson['secure_url'];
  } else {
    print("failed to upload. status: ${response.statusCode}");
    return null;
  }
}