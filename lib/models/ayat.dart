import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

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

  void ensureTextIsLoaded(final ByteBuffer quranTextUtf8) {
    if (text.isNotEmpty) return;
    if (ayat != null) {
      ayat!.text = getAyahForIdx(ayat!.ayahIdx, quranTextUtf8).text;
    } else if (mutashabiha != null) {
      mutashabiha!.src.text =
          getAyahForIdx(mutashabiha!.src.ayahIdx, quranTextUtf8).text;
      for (final m in mutashabiha!.matches) {
        m.text = getAyahForIdx(m.ayahIdx, quranTextUtf8).text;
      }
    }
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

extension ValueNotifierToggle on ValueNotifier<bool> {
  void toggle() {
    value = !value;
  }
}

class ParaAyatModel extends ChangeNotifier {
  Map<int, List<Ayat>> _paraAyats = {};
  ValueNotifier<int> currentParaNotifier = ValueNotifier<int>(1);
  Timer? timer;

  @override
  void dispose() async {
    currentParaNotifier.dispose();
    if (timer?.isActive ?? false) {
      timer?.cancel();
      await saveToDisk();
    }
    super.dispose();
  }

  void persist() {
    timer?.cancel();
    timer = Timer(const Duration(seconds: 1), () => saveToDisk());
  }

  set onParaChange(VoidCallback cb) => currentParaNotifier.addListener(cb);

  List<Ayat> get ayahs => _paraAyats[currentPara] ?? [];

  List<AyatOrMutashabiha> ayahsAndMutashabihasList(
      List<Mutashabiha> allParaMutashabihas) {
    List<AyatOrMutashabiha> list = [];
    for (final a in ayahs) {
      bool wasMutashabiha = false;
      for (final m in allParaMutashabihas) {
        if (m.src.ayahIdx == a.ayahIdx) {
          list.add(AyatOrMutashabiha(ayat: null, mutashabiha: m));
          wasMutashabiha = true;
        }
      }
      if (!wasMutashabiha) {
        list.add(AyatOrMutashabiha(ayat: a, mutashabiha: null));
      }
    }
    return list;
  }

  int get currentPara => currentParaNotifier.value;

  void addAyahs(List<Ayat> newAyahs) {
    _setParaAyahs(currentPara, newAyahs);
    resetSelection();
    notifyListeners();
    persist();
  }

  void _setParaAyahs(int para, List<Ayat> newAyahs) {
    if (newAyahs.isEmpty) {
      return;
    }

    List<Ayat> existingAyahs = _paraAyats[para] ?? [];

    Ayat first = newAyahs.first;
    for (final a in existingAyahs) {
      if (a.ayahIdx == first.ayahIdx) {
        for (final w in first.markedWords) {
          if (!a.markedWords.contains(w)) {
            a.markedWords.add(w);
          }
        }
        newAyahs.removeAt(0);
        if (newAyahs.isEmpty) {
          break;
        }
        first = newAyahs.first;
      }
    }

    if (newAyahs.isNotEmpty) {
      existingAyahs.addAll(newAyahs);
    }

    existingAyahs.sort((a, b) {
      return a.ayahIdx - b.ayahIdx;
    });

    _paraAyats[para] = existingAyahs;
    persist();
  }

  void setCurrentPara(int para) {
    if (para == currentPara) return;
    // wrap around
    if (para <= 0) {
      para = 30;
    } else if (para > 30) {
      para = 1;
    }

    currentParaNotifier.value = para;
    resetSelection();
    notifyListeners();

    // trigger a save
    persist();
  }

  void removeSelectedAyahs() {
    final list = _paraAyats[currentPara];
    if (list == null) return;
    list.removeWhere((final Ayat ayah) => ayah.selected ?? false);
    _paraAyats[currentPara] = list;
    notifyListeners();
    persist();
  }

  /// Remove ayats from given para index
  void removeAyats(int paraIndex, int absoluteAyahIndex, int wordIndex) {
    final List<Ayat>? ayahs = _paraAyats[paraIndex + 1];
    if (ayahs == null) return;
    int removeAyahIndex = -1;
    int i = 0;
    for (final a in ayahs) {
      if (a.ayahIdx == absoluteAyahIndex) {
        if (a.markedWords.contains(wordIndex)) {
          a.markedWords.remove(wordIndex);
          if (a.markedWords.isEmpty) {
            removeAyahIndex = i;
          }
        }
      }
      i++;
    }

    if (removeAyahIndex != -1) {
      ayahs.removeAt(removeAyahIndex);
    }

    _paraAyats[paraIndex + 1] = ayahs;
    notifyListeners();
    persist();
  }

  void resetSelection() {
    for (var i = 0; i < ayahs.length; i++) {
      ayahs[i].selected = false;
    }
  }

  void selectAll() {
    if (ayahs.isEmpty) return;
    bool value = ayahs.first.selected ?? false;
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
      index < ayahs.length && (ayahs[index].selected ?? false);

  void merge(Map<int, List<Ayat>> paraAyahs) {
    for (final e in paraAyahs.entries) {
      _setParaAyahs(e.key, e.value);
    }
    // if current para change, notify
    if (paraAyahs.containsKey(currentParaNotifier.value)) {
      notifyListeners();
    }
  }

  Future<void> _resetfromJson(Map<String, dynamic> json) async {
    final Map<int, List<Ayat>> paraAyats = {};
    try {
      for (final MapEntry<String, dynamic> entry in json.entries) {
        final int? para = int.tryParse(entry.key);
        if (para == null || para > 30 || para < 1) continue;

        final paraJson = entry.value as Map<String, dynamic>;
        List<Ayat> paraData = [];

        var ayahJsons = paraJson["ayats"] as List<dynamic>?;
        if (ayahJsons != null) {
          for (final dynamic a in ayahJsons) {
            if (a is int) {
              paraData.add(Ayat("", [0], ayahIdx: a));
            } else {
              final int idx = a['idx'];
              final List<int> wordIdxes = [
                for (final w in a['words']) w as int
              ];
              paraData.add(Ayat("", wordIdxes, ayahIdx: idx));
            }
          }
        }

        // migrate old stuff
        var mutashabihasJson = paraJson["mutashabihas"] as List<dynamic>?;
        if (mutashabihasJson != null) {
          for (final m in mutashabihasJson) {
            if (m == null) continue;
            int ctx = 0; // no context here
            MutashabihaAyat src = ayatFromJsonObj(m["src"], null, ctx);
            paraData.add(Ayat("", [0], ayahIdx: src.ayahIdx));
          }
        }

        if (paraData.isEmpty) continue;
        paraData.sort((a, b) {
          return a.ayahIdx - b.ayahIdx;
        });

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
    await _resetfromJson(json);
    return true;
  }

  Future<String> backup() async => await saveToDisk(fileName: "ayatsdb_backup");

  Future<String> saveToDisk({String? fileName}) async {
    String path =
        await utils.saveJsonToDisk(jsonStringify(), fileName ?? "ayatsdb");
    return path;
  }

  String jsonStringify() =>
      const JsonEncoder.withIndent("  ").convert(toJson());

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    for (final kv in _paraAyats.entries) {
      List<Ayat> ayats = [for (final a in kv.value) a];
      json[kv.key.toString()] = {'ayats': ayats};
    }
    json["currentPara"] = currentParaNotifier.value;
    return json;
  }
}
