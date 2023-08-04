import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:async';
import 'package:quran_memorization_helper/utils/utils.dart' as utils;

class Settings extends ChangeNotifier {
  static final Settings _instance = Settings._private();
  static Settings get instance => _instance;
  Timer? timer;

  // The font size of ayahs
  int _fontSize = 24;
  int get fontSize => _fontSize;
  set fontSize(int val) {
    _fontSize = val;
    notifyListeners();
    persist();
  }

  // The word spacing between words of ayah
  int _wordSpacing = 1;
  int get wordSpacing => _wordSpacing;
  set wordSpacing(int val) {
    _wordSpacing = val;
    notifyListeners();
    persist();
  }

  factory Settings() {
    return _instance;
  }

  void saveToDisk() async {
    Map<String, dynamic> map = {
      'fontSize': fontSize,
      'wordSpacing': wordSpacing
    };
    String json = const JsonEncoder.withIndent("  ").convert(map);
    await utils.saveJsonToDisk(json, "settings");
  }

  void readSettings() async {
    final Map<String, dynamic>? json = await utils.readJsonFile("settings");
    if (json == null) return;
    _fontSize = json["fontSize"] ?? 24;
    _wordSpacing = json["wordSpacing"] ?? 1;
  }

  void persist() {
    if (timer == null || (timer?.isActive ?? false)) {
      timer = Timer(const Duration(seconds: 2), saveToDisk);
    }
  }

  Settings._private();
}
