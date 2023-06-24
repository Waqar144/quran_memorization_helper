import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

extension ValueNotifierToggle on ValueNotifier<bool> {
  void toggle() {
    value = !value;
  }
}

class Ayat {
  Ayat(this.text);
  String text = "";
  int count = 0;

  Ayat.fromJson(Map<String, dynamic> json)
      : text = json["text"],
        count = json["count"];

  Map<String, dynamic> toJson() => {"text": text, "count": count};

  @override
  bool operator ==(Object other) {
    return (other is Ayat) && other.text == text;
  }

  @override
  int get hashCode => text.hashCode;
}

enum ImportDBResult { Success, PathDoesntExist }

class ParaAyatModel extends ChangeNotifier {
  Map<int, List<Ayat>> _paraAyats = {};
  ValueNotifier<int> currentParaNotifier = ValueNotifier<int>(1);

  set onParaChange(VoidCallback cb) => currentParaNotifier.addListener(cb);

  List<Ayat> get ayahs => _paraAyats[currentPara] ?? [];

  int get currentPara => currentParaNotifier.value;

  void setData(Map<int, List<Ayat>> data) {
    _paraAyats = data;
    notifyListeners();
  }

  void setAyahs(List<Ayat> ayahs) {
    _paraAyats[currentPara] = ayahs;
    notifyListeners();
  }

  void setCurrentPara(int para) {
    if (para == currentPara) return;
    currentParaNotifier.value = para;
    notifyListeners();
  }

  void removeAyahs(Set<int> indices) {
    if (indices.isEmpty) return;
    List<Ayat> ayahs = _paraAyats[currentPara] ?? [];
    for (final int index in indices) {
      ayahs.removeAt(index);
    }
    notifyListeners();
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
    notifyListeners();
  }

  Future<ImportDBResult> readJsonDB({String path = ""}) async {
    if (path.isEmpty) {
      final Directory dir = await getApplicationDocumentsDirectory();
      path = dir.path;
      path = "$path${Platform.pathSeparator}ayatsdb.json";
    }
    final jsonFile = File(path);
    if (!await jsonFile.exists()) {
      return ImportDBResult.PathDoesntExist;
    }

    final String contents = await jsonFile.readAsString();
    final Map<String, dynamic> jsonObj = jsonDecode(contents);
    _resetfromJson(jsonObj);
    return ImportDBResult.Success;
  }

  Future<String> saveToDisk() async {
    Directory dir = await getApplicationDocumentsDirectory();
    String path = "${dir.path}${Platform.pathSeparator}ayatsdb.json";
    String json = const JsonEncoder.withIndent("  ").convert(toJson());
    File f = File(path);
    await f.writeAsString(json);
    return path;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> out = {};
    _paraAyats.forEach((int para, List<Ayat> ayats) {
      out.putIfAbsent(para.toString(), () => ayats);
    });
    return out;
  }
}
