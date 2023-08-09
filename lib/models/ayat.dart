import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import 'package:quran_memorization_helper/utils/utils.dart' as utils;
import 'package:quran_memorization_helper/quran_data/ayah_offsets.dart';
import 'package:quran_memorization_helper/quran_data/ayat.dart';

/// Represents an item that is shown in main page ayah list
class AyatOrMutashabiha {
  final Ayat? ayat;
  final Mutashabiha? mutashabiha;
  const AyatOrMutashabiha({this.ayat, this.mutashabiha});

  int getAyahIdx() {
    if (ayat != null) {
      return ayat!.ayahIdx;
    } else if (mutashabiha != null) {
      return mutashabiha!.src.ayahIdx;
    }
    throw "Invalid AyatOrMutashabiha item..";
  }

  bool get selected {
    if (ayat != null) {
      return ayat!.selected ?? false;
    } else if (mutashabiha != null) {
      return mutashabiha!.src.selected ?? false;
    }
    return false;
  }

  set selected(bool s) {
    if (ayat != null) {
      ayat!.selected = s;
    } else if (mutashabiha != null) {
      mutashabiha!.src.selected = s;
    }
  }

  String get text {
    if (ayat != null) {
      return ayat!.text;
    } else if (mutashabiha != null) {
      return mutashabiha!.src.text;
    }
    throw "Invalid AyatOrMutashabiha item..";
  }
}

int _comparator(AyatOrMutashabiha a, AyatOrMutashabiha b) {
  int aIdx = a.getAyahIdx();
  int bIdx = b.getAyahIdx();
  return aIdx - bIdx;
}

extension ValueNotifierToggle on ValueNotifier<bool> {
  void toggle() {
    value = !value;
  }
}

class ParaAyatModel extends ChangeNotifier {
  Map<int, List<AyatOrMutashabiha>> _paraAyats = {};
  ValueNotifier<int> currentParaNotifier = ValueNotifier<int>(1);

  @override
  void dispose() {
    currentParaNotifier.dispose();
    _paraAyats = {};
    super.dispose();
  }

  set onParaChange(VoidCallback cb) => currentParaNotifier.addListener(cb);

  List<AyatOrMutashabiha> get ayahs => _paraAyats[currentPara] ?? [];

  int get currentPara => currentParaNotifier.value;

  void addAyahs(List<Ayat> newAyahs) {
    _setParaAyahs(currentPara, newAyahs);
    resetSelection();
    notifyListeners();
  }

  void _setParaAyahs(int para, List<Ayat> newAyahs) {
    List<AyatOrMutashabiha> existingData = _paraAyats[para] ?? [];
    final List<Ayat> existingAyahs = [
      for (final a in existingData)
        if (a.ayat != null) a.ayat!
    ];
    existingData.removeWhere((a) => a.ayat != null);

    Set<Ayat> uniqueAyahs = {};
    uniqueAyahs.addAll(existingAyahs);
    uniqueAyahs.addAll(newAyahs);
    if (uniqueAyahs.isEmpty) return;

    for (final a in uniqueAyahs) {
      existingData.add(AyatOrMutashabiha(ayat: a, mutashabiha: null));
    }

    existingData.sort(_comparator);
    _paraAyats[para] = existingData;
  }

  void setParaMutashabihas(int paraNum, List<Mutashabiha> newMutashabihas) {
    List<AyatOrMutashabiha> existingData = _paraAyats[paraNum] ?? [];
    // copy out all mutashabihas for this para
    final List<Mutashabiha> existingMutashabihas = [
      for (final m in existingData)
        if (m.mutashabiha != null) m.mutashabiha!
    ];

    // remove them from main list
    existingData.removeWhere((a) => a.mutashabiha != null);

    Set<Mutashabiha> uniqueMutashabihas = {};
    uniqueMutashabihas.addAll(existingMutashabihas);
    uniqueMutashabihas.addAll(newMutashabihas);
    if (uniqueMutashabihas.isEmpty) return;

    for (final m in uniqueMutashabihas) {
      existingData.add(AyatOrMutashabiha(ayat: null, mutashabiha: m));
    }

    existingData.sort(_comparator);
    _paraAyats[paraNum] = existingData;
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
    final list = _paraAyats[currentPara];
    if (list == null) return;
    list.removeWhere((final AyatOrMutashabiha ayah) => ayah.selected);
    _paraAyats[currentPara] = list;
    notifyListeners();
  }

  /// Remove ayats from given para index
  void removeAyats(int paraIndex, List<int> absoluteAyahIndexes) {
    final List<AyatOrMutashabiha>? ayahs = _paraAyats[paraIndex + 1];
    if (ayahs == null) return;
    ayahs.removeWhere((AyatOrMutashabiha a) =>
        a.ayat != null && absoluteAyahIndexes.contains(a.getAyahIdx()));
    _paraAyats[paraIndex] = ayahs;
    notifyListeners();
  }

  /// Remove mutashabiha from given para index
  void removeMutashabihas(int paraIndex, List<Mutashabiha> mutashabihas) {
    final List<AyatOrMutashabiha>? ayahs = _paraAyats[paraIndex + 1];
    if (ayahs == null) return;
    ayahs.removeWhere((AyatOrMutashabiha a) {
      if (a.mutashabiha != null) {
        for (final m in mutashabihas) {
          if (m.src.surahAyahIndexes == a.mutashabiha!.src.surahAyahIndexes) {
            return true;
          }
        }
      }
      return false;
    });
    _paraAyats[paraIndex] = ayahs;
    notifyListeners();
  }

  void resetSelection() {
    for (var i = 0; i < ayahs.length; i++) {
      ayahs[i].selected = false;
    }
  }

  void selectAll() {
    if (ayahs.isEmpty) return;
    bool value = ayahs.first.selected;
    for (var i = 0; i < ayahs.length; i++) {
      ayahs[i].selected = !value;
    }
    notifyListeners();
  }

  void setIndexSelected(int index, bool select) {
    if (ayahs.isNotEmpty && index < ayahs.length) {
      ayahs[index].selected = select ? select : false;
    } else {
      throw "Invalid index to select: $index";
    }
  }

  bool isIndexSelected(int index) =>
      index < ayahs.length && (ayahs[index].selected);

  void merge(Map<int, List<Ayat>> paraAyahs) {
    for (final e in paraAyahs.entries) {
      _setParaAyahs(e.key, e.value);
    }
    // if current para change, notify
    if (paraAyahs.containsKey(currentParaNotifier.value)) {
      notifyListeners();
    }
  }

  void _resetfromJson(Map<String, dynamic> json) async {
    final data = await rootBundle.load("assets/quran.txt");

    final Map<int, List<AyatOrMutashabiha>> paraAyats = {};
    try {
      for (final MapEntry<String, dynamic> entry in json.entries) {
        final int? para = int.tryParse(entry.key);
        if (para == null || para > 30 || para < 1) continue;

        final paraJson = entry.value as Map<String, dynamic>;
        List<AyatOrMutashabiha> paraData = [];

        var ayahJsons = paraJson["ayats"] as List<dynamic>?;
        if (ayahJsons != null) {
          Set<int> uniqueAyahIdexes = {for (final a in ayahJsons) a as int};
          List<int> ayahIndexes = uniqueAyahIdexes.toList();
          ayahIndexes.sort();
          for (int a in ayahIndexes) {
            final ayat = getAyahForIdx(a, data.buffer);
            paraData.add(AyatOrMutashabiha(ayat: ayat, mutashabiha: null));
          }
        }

        var mutashabihasJson = paraJson["mutashabihas"] as List<dynamic>?;
        if (mutashabihasJson != null) {
          for (final m in mutashabihasJson) {
            if (m == null) continue;
            int ctx = 0; // no context here
            MutashabihaAyat src = ayatFromJsonObj(m["src"], data.buffer, ctx);
            List<MutashabihaAyat> matches = [];
            for (final match in m["muts"]) {
              matches.add(ayatFromJsonObj(match, data.buffer, ctx));
            }
            paraData.add(AyatOrMutashabiha(
                ayat: null, mutashabiha: Mutashabiha(src, matches)));
          }
        }

        if (paraData.isEmpty) continue;
        paraData.sort(_comparator);

        paraAyats[para] = paraData;
      }
    } catch (e) {
      print(e);
      rethrow;
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
    Map<String, dynamic> json = {};
    for (final kv in _paraAyats.entries) {
      List<Ayat> ayats = [
        for (final a in kv.value)
          if (a.ayat != null) a.ayat!
      ];
      List<Mutashabiha> mutashabihas = [
        for (final m in kv.value)
          if (m.mutashabiha != null) m.mutashabiha!
      ];
      json[kv.key.toString()] = {'ayats': ayats, 'mutashabihas': mutashabihas};
    }
    json["currentPara"] = currentParaNotifier.value;
    return json;
  }
}
