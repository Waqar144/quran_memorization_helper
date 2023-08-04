import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:path_provider/path_provider.dart';

Future<String> saveJsonToDisk(String json, String fileName) async {
  if (json.isEmpty) throw "Empty json";
  Directory dir = await getApplicationDocumentsDirectory();
  String path = "${dir.path}${Platform.pathSeparator}$fileName.json";
  File f = File(path);
  await f.writeAsString(json);
  return path;
}

Future<Map<String, dynamic>?> readJsonFile(String fileName) async {
  final Directory dir = await getApplicationDocumentsDirectory();
  String path = dir.path;
  path = "$path${Platform.pathSeparator}$fileName.json";
  try {
    return await readJsonFromFilePath(path);
  } catch (e) {
    return {};
  }
}

Future<Map<String, dynamic>?> readJsonFromFilePath(String path) async {
  final jsonFile = File(path);
  if (!await jsonFile.exists()) {
    throw "file: '$path' doesn't exits!";
  }

  final String contents = await jsonFile.readAsString();
  return jsonDecode(contents);
}
