import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:quran_memorization_helper/utils/utils.dart' as utils;

extension ValueNotifierToggle on ValueNotifier<bool> {
  void toggle() {
    value = !value;
  }
}

class Ayat {
  Ayat(this.text);
  String text = "";
  bool? selected;

  Ayat.fromJson(Map<String, dynamic> json) : text = json["text"];

  Map<String, dynamic> toJson() => {"text": text};

  @override
  bool operator ==(Object other) {
    return (other is Ayat) && other.text == text;
  }

  @override
  int get hashCode => text.hashCode;
}

class ParaAyatModel extends ChangeNotifier {
  Map<int, List<Ayat>> _paraAyats = {};
  ValueNotifier<int> currentParaNotifier = ValueNotifier<int>(1);

  @override
  void dispose() {
    currentParaNotifier.dispose();
    _paraAyats = {};
    super.dispose();
  }

  set onParaChange(VoidCallback cb) => currentParaNotifier.addListener(cb);

  List<Ayat> get ayahs => _paraAyats[currentPara] ?? [];

  int get currentPara => currentParaNotifier.value;

  void setAyahs(List<Ayat> ayahs) {
    _paraAyats[currentPara] = ayahs;
    resetSelection();
    notifyListeners();
  }

  void setCurrentPara(int para) {
    if (para == currentPara) return;
    currentParaNotifier.value = para;
    resetSelection();
    notifyListeners();

    // trigger a save
    Future.delayed(const Duration(seconds: 5), () {
      saveToDisk();
    });
  }

  void removeSelectedAyahs() {
    List<Ayat> ayahs = _paraAyats[currentPara] ?? [];
    ayahs.removeWhere((final Ayat ayah) => ayah.selected ?? false);
    setAyahs(ayahs);
  }

  void resetSelection() {
    for (var i = 0; i < ayahs.length; i++) {
      ayahs[i].selected = null;
    }
  }

  void selectAll() {
    for (var i = 0; i < ayahs.length; i++) {
      ayahs[i].selected = !(ayahs[i].selected ?? false);
    }
    notifyListeners();
  }

  void setIndexSelected(int index, bool select) {
    if (ayahs.isNotEmpty && index < ayahs.length) {
      ayahs[index].selected = select ? select : null;
    } else {
      throw "Invalid index to select: $index";
    }
  }

  bool isIndexSelected(int index) =>
      index < ayahs.length && (ayahs[index].selected ?? false);

  void merge(Map<int, List<Ayat>> paraAyahs) {
    for (final e in paraAyahs.entries) {
      List<Ayat> existingAyahs = _paraAyats[e.key] ?? [];
      List<Ayat> toMergeAyahs = e.value;
      Set<Ayat> newAyahs = {...existingAyahs, ...toMergeAyahs};
      _paraAyats[e.key] = newAyahs.toList();
    }
    // if current para change, notify
    if (paraAyahs.containsKey(currentParaNotifier.value)) {
      notifyListeners();
    }
  }

  void _resetfromJson(Map<String, dynamic> json) {
    final Map<int, List<Ayat>> paraAyats = {};
    for (final MapEntry<String, dynamic> entry in json.entries) {
      final int? para = int.tryParse(entry.key);
      if (para == null || para > 30 || para < 1) continue;

      var ayahJsons = entry.value as List<dynamic>?;
      if (ayahJsons == null) continue;
      final List<Ayat> ayats = [
        for (final dynamic a in ayahJsons) Ayat.fromJson(a)
      ];
      paraAyats[para] = ayats;
    }

    _paraAyats = paraAyats;
    currentParaNotifier.value = json["currentPara"] ?? 1;
    resetSelection();
    notifyListeners();
  }

  Future<bool> readJsonDB({String? path}) async {
    final Map<String, dynamic>? json = path == null
        ? await utils.readJsonFile("ayatsdb")
        : await utils.readJsonFromFilePath(path);
    if (json == null) {
      return false;
    }
    _resetfromJson(json);
    return true;
  }

  Future<String> backup() async => await saveToDisk(fileName: "ayatsdb_backup");

  Future<String> saveToDisk({String? fileName}) async {
    String json = const JsonEncoder.withIndent("  ").convert(toJson());
    return utils.saveJsonToDisk(json, fileName ?? "ayatsdb");
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> out =
        _paraAyats.map((para, ayats) => MapEntry(para.toString(), ayats));
    out["currentPara"] = currentParaNotifier.value;
    return out;
  }
}
