import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:async';
import 'utils.dart' as utils;

class Settings extends ChangeNotifier {
  static final Settings _instance = Settings._private();
  static Settings get instance => _instance;
  Timer? timer;

  int _fontSize = 24;
  int get fontSize => _fontSize;
  set fontSize(int val) {
    _fontSize = val;
    notifyListeners();
    persist();
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

  void persist() {
    if (timer == null || (timer?.isActive ?? false)) {
      timer = Timer(const Duration(seconds: 2), saveToDisk);
    }
  }

  Settings._private();
}
