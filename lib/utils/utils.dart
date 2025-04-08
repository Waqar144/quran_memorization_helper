import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quran_memorization_helper/models/settings.dart';

Future<String> saveJsonToDisk(String json, String fileName) async {
  if (json.isEmpty) throw "Empty json";
  Directory dir = await getApplicationDocumentsDirectory();

  final basePath = "${dir.path}${Platform.pathSeparator}";

  // 1. Write the file as filename_new
  final String newFilename = "${fileName}_new.json";
  final String path = "$basePath$newFilename";
  File f = File(path);
  await f.writeAsString(json);

  // 2. Rename the old file to oldfile_bck.json
  File oldFile = File("$basePath$fileName.json");
  if (await oldFile.exists()) {
    await oldFile.rename("$basePath${fileName}_bck.json");
  }

  // 3. Rename the new file fileName.json
  await f.rename("$basePath$fileName.json");

  // done
  return path;
}

Future<Map<String, dynamic>> readJsonFile(String fileName) async {
  final Directory dir = await getApplicationDocumentsDirectory();
  final basePath = "${dir.path}${Platform.pathSeparator}";
  final path = "$basePath$fileName.json";
  try {
    // try normal
    if (await File(path).exists()) {
      return await readJsonFromFilePath(path);
    } else {
      // try backup
      final backupPath = "$basePath${fileName}_bck.json";
      if (await File(backupPath).exists()) {
        return await readJsonFromFilePath(backupPath);
      }
      // otherwise just return empty
      return {};
    }
  } catch (e) {
    rethrow;
  }
}

Future<Map<String, dynamic>> readJsonFromFilePath(String path) async {
  try {
    final jsonFile = File(path);
    if (!await jsonFile.exists()) {
      throw "file: '$path' doesn't exits!";
    }

    final String contents = await jsonFile.readAsString();
    return jsonDecode(contents) as Map<String, dynamic>;
  } catch (e) {
    rethrow;
  }
}

void showSnackBarMessage(
  BuildContext context,
  String message, {
  bool error = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: Duration(seconds: error ? 5 : 2),
      backgroundColor: error ? Colors.red : Colors.green,
    ),
  );
}

String toUrduNumber(int num) {
  final Uint16List numMap = Uint16List.fromList(const <int>[
    0x6F0,
    0x6F0 + 1,
    0x6F0 + 2,
    0x6F0 + 3,
    0x6F0 + 4,
    0x6F0 + 5,
    0x6F0 + 6,
    0x6F0 + 7,
    0x6F0 + 8,
    0x6F0 + 9,
  ]);
  final numStr = num.toString();
  String ret = "";
  for (final c in numStr.codeUnits) {
    ret += String.fromCharCode(numMap[c - 48]);
  }
  return ret;
}

String toArabicNumber(int num) {
  const List<String> arabicNumbers = [
    "٠",
    "١",
    "٢",
    "٣",
    "٤",
    "٥",
    "٦",
    "٧",
    "٨",
    "٩",
  ];
  final numStr = num.toString();
  String ret = "";
  for (final c in numStr.codeUnits) {
    ret += arabicNumbers[c - 48];
  }
  return ret;
}

const String urduKhatma = "\u06D4";

String getQuranTextFolder() {
  return Settings.instance.mushaf == Mushaf.Indopak16Line ? "16line" : "15line";
}

String getQuranFont() {
  return Settings.instance.mushaf == Mushaf.Indopak16Line
      ? "Al Mushaf"
      : "Uthmanic";
}

String paraText() {
  return Settings.instance.mushaf == Mushaf.Indopak16Line ? "Para" : "Juz";
}

bool isBigScreen() {
  final view = WidgetsBinding.instance.platformDispatcher.views.firstOrNull;
  if (view != null) {
    final data = MediaQueryData.fromView(view);
    return data.size.shortestSide > 550;
  }
  return false;
}
