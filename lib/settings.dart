import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'utils.dart' as utils;

class Settings extends ChangeNotifier {
  static final Settings _instance = Settings._private();
  static Settings get instance => _instance;

  int _fontSize = 24;
  int get fontSize => _fontSize;
  set fontSize(int val) {
    _fontSize = val;
    notifyListeners();
  }

  factory Settings() {
    return _instance;
  }

  void saveToDisk() async {
    Map<String, dynamic> map = {'fontSize': fontSize};
    String json = const JsonEncoder.withIndent("  ").convert(map);
    await utils.saveJsonToDisk(json, "settings");
  }

  void readSettings() async {
    final Map<String, dynamic>? json = await utils.readJsonFile("settings");
    if (json == null) return;
    _fontSize = json["fontSize"] ?? 24;
  }

  Settings._private();
}
