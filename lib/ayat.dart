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
  List<bool?> selection = [];

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
    Future.delayed(Duration(seconds: 5), () {
      saveToDisk();
    });
  }

  void removeSelectedAyahs() {
    if (selection.isEmpty) return;
    List<Ayat> ayahs = _paraAyats[currentPara] ?? [];
    for (int i = 0; i < selection.length; ++i) {
      if (selection[i] ?? false) ayahs.removeAt(i);
    }
    setAyahs(ayahs);
  }

  void resetSelection() {
    selection.clear();
    selection.length = ayahs.length;
  }

  void setIndexSelected(int index, bool select) {
    if (ayahs.isNotEmpty && index < ayahs.length) {
      selection[index] = select;
    } else {
      throw "Invalid index to select: $index";
    }
  }

  bool isIndexSelected(int index) =>
      index < selection.length && (selection[index] ?? false);

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

  Future<String> backup() async {
    Directory? dir = await getDownloadsDirectory();
    if (dir == null) return "";
    final path = await saveToDisk(dir: dir);
    return path;
  }

  Future<String> saveToDisk({Directory? dir}) async {
    dir ??= await getApplicationDocumentsDirectory();
    String path = "${dir.path}${Platform.pathSeparator}ayatsdb.json";
    String json = const JsonEncoder.withIndent("  ").convert(toJson());
    File f = File(path);
    await f.writeAsString(json);
    return path;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> out =
        _paraAyats.map((para, ayats) => MapEntry(para.toString(), ayats));
    out["currentPara"] = currentParaNotifier.value;
    return out;
  }
}
