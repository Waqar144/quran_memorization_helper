import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:core';
import 'package:quran_memorization_helper/utils/utils.dart' as utils;

// ignore: constant_identifier_names
enum Mushaf { Indopak16Line, Uthmani15Line }

const _minFontSize = 24;

class Settings extends ChangeNotifier {
  static final Settings _instance = Settings._private();
  static Settings get instance => _instance;
  int _currentReadingPara = 1;
  int _currentReadingPage = 0;
  Timer? timer;
  ThemeMode _themeMode = ThemeMode.system;
  Mushaf _mushaf = Mushaf.Indopak16Line;
  String _translationFile = "";
  bool _tapToShowTranslation = false;
  bool _reflowMode = false;

  // constants
  static const double wordSpacing = 1.0;

  // The font size of ayahs if reflow mode is enabled
  int _fontSize = _minFontSize;
  int get fontSize => _reflowMode ? _fontSize : _minFontSize;
  set fontSize(int val) {
    _fontSize = val;
    notifyListeners();
    persist();
  }

  int get currentReadingPara => _currentReadingPara;
  set currentReadingPara(int val) {
    _currentReadingPara = val;
    persist();
  }

  int get currentReadingPage => _currentReadingPage;
  set currentReadingPage(int val) {
    _currentReadingPage = val;
    persist();
  }

  ThemeMode get themeMode => _themeMode;
  set themeMode(ThemeMode m) {
    if (m != _themeMode) {
      _themeMode = m;
      notifyListeners();
      persist();
    }
  }

  Mushaf get mushaf => _mushaf;
  set mushaf(Mushaf m) {
    if (m != _mushaf) {
      _mushaf = m;
      notifyListeners();
      persist();
    }
  }

  String get translationFile => _translationFile;
  set translationFile(String file) {
    if (file != _translationFile) {
      _translationFile = file;
      notifyListeners();
      persist();
    }
  }

  bool get tapToShowTranslation => _tapToShowTranslation;
  set tapToShowTranslation(bool newValue) {
    if (newValue != _tapToShowTranslation) {
      _tapToShowTranslation = newValue;
      notifyListeners();
      persist();
    }
  }

  bool get reflowMode => _reflowMode;
  set reflowMode(bool s) {
    if (s != _reflowMode) {
      _reflowMode = s;
      notifyListeners();
      persist();
    }
  }

  factory Settings() {
    return _instance;
  }

  Future<void> saveToDisk() async {
    Map<String, dynamic> map = {
      'currentReadingPara': _currentReadingPara,
      'currentReadingScrollOffset': _currentReadingPage,
      'themeMode': _themeMode.index,
      'translationFile': _translationFile,
      'tapToShowTranslation': _tapToShowTranslation,
      'mushaf': _mushaf.index,
      'reflowMode': _reflowMode,
      'fontSize': _fontSize,
    };
    String json = const JsonEncoder.withIndent("  ").convert(map);
    await utils.saveJsonToDisk(json, "settings");
  }

  Future<void> readSettings() async {
    try {
      final Map<String, dynamic> json = await utils.readJsonFile("settings");
      _currentReadingPara = json["currentReadingPara"] ?? 1;
      _currentReadingPage = json["currentReadingScrollOffset"] ?? 0;
      _themeMode =
          ThemeMode.values[json["themeMode"] ?? ThemeMode.system.index];
      _translationFile = json["translationFile"] ?? "";
      _tapToShowTranslation = json["tapToShowTranslation"] ?? false;
      _mushaf = Mushaf.values[json["mushaf"] ?? Mushaf.Indopak16Line.index];
      _reflowMode = json["reflowMode"] ?? false;
      _fontSize = json["fontSize"] ?? _minFontSize;
      if (_fontSize < _minFontSize) {
        _fontSize = _minFontSize;
      }
    } catch (e) {
      // nothing for now
    }
  }

  Future<void> saveScrollPosition(int paraNumber, int page) async {
    // nothing changed?
    if (currentReadingPara == paraNumber && page == currentReadingPage) {
      return;
    }
    currentReadingPara = paraNumber;
    currentReadingPage = page;
    await saveToDisk();
  }

  void saveScrollPositionDelayed(int paraNumber, int page) {
    currentReadingPara = paraNumber;
    currentReadingPage = page;
    persist(seconds: 2);
  }

  void persist({int seconds = 1}) {
    timer?.cancel();
    timer = Timer(Duration(seconds: seconds), saveToDisk);
  }

  Settings._private();
}
