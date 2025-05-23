import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:core';
import 'package:quran_memorization_helper/utils/utils.dart' as utils;
import 'package:quran_memorization_helper/quran_data/pages.dart';

// ignore: constant_identifier_names
enum Mushaf { Indopak16Line, Uthmani15Line, Indopak15Line, Indopak13Line }

bool isIndoPak(Mushaf m) {
  return switch (m) {
    Mushaf.Indopak13Line ||
    Mushaf.Indopak15Line ||
    Mushaf.Indopak16Line => true,
    Mushaf.Uthmani15Line => false,
  };
}

const _minFontSize = 24;

class Settings extends ChangeNotifier {
  static final Settings _instance = Settings._private();
  static Settings get instance => _instance;
  int _currentReadingPage = 0;
  Timer? timer;
  ThemeMode _themeMode = ThemeMode.system;
  Mushaf _mushaf = Mushaf.Indopak16Line;
  String _translationFile = "";
  bool _tapToShowTranslation = false;
  bool _colorMutashabihat = true;
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

  int get currentReadingPage => _currentReadingPage;

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

  bool get colorMutashabihat => _colorMutashabihat;
  set colorMutashabihat(bool newValue) {
    if (newValue != _colorMutashabihat) {
      _colorMutashabihat = newValue;
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

  Map<String, dynamic> toJson() {
    return {
      'currentReadingPage': _currentReadingPage,
      'themeMode': _themeMode.index,
      'translationFile': _translationFile,
      'tapToShowTranslation': _tapToShowTranslation,
      'mushaf': _mushaf.index,
      'reflowMode': _reflowMode,
      'fontSize': _fontSize,
    };
  }

  void initFromJson(Map<String, dynamic> json) {
    int? currentReadingPara = json["currentReadingPara"];
    int? oldCurrentReadingPage = json["currentReadingScrollOffset"];

    _themeMode = ThemeMode.values[json["themeMode"] ?? ThemeMode.system.index];
    _translationFile = json["translationFile"] ?? "";
    _tapToShowTranslation = json["tapToShowTranslation"] ?? false;
    _mushaf = Mushaf.values[json["mushaf"] ?? Mushaf.Indopak16Line.index];
    _reflowMode = json["reflowMode"] ?? false;
    _fontSize = json["fontSize"] ?? _minFontSize;
    if (_fontSize < _minFontSize) {
      _fontSize = _minFontSize;
    }

    if (currentReadingPara != null && oldCurrentReadingPage != null) {
      int start = paraStartPage(currentReadingPara - 1, _mushaf);
      int page = start + oldCurrentReadingPage;
      _currentReadingPage = page;
    } else {
      _currentReadingPage = json["currentReadingPage"] ?? 0;
    }
  }

  Future<void> saveToDisk() async {
    String json = const JsonEncoder.withIndent("  ").convert(toJson());
    await utils.saveJsonToDisk(json, "settings");
  }

  Future<void> readSettings() async {
    try {
      final Map<String, dynamic> json = await utils.readJsonFile("settings");
      initFromJson(json);
    } catch (e) {
      // nothing for now
    }
  }

  Future<void> saveScrollPosition(int page) async {
    // nothing changed?
    if (page == currentReadingPage) {
      return;
    }
    _currentReadingPage = page;
    await saveToDisk();
  }

  void saveScrollPositionDelayed(int page) {
    if (page == currentReadingPage) {
      return;
    }
    _currentReadingPage = page;
    persist(seconds: 2);
  }

  void persist({int seconds = 1}) {
    timer?.cancel();
    timer = Timer(Duration(seconds: seconds), saveToDisk);
  }

  Settings._private();
}
