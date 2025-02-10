import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:quran_memorization_helper/utils/utils.dart' as utils;
import 'package:quran_memorization_helper/quran_data/ayah_offsets.dart';
import 'package:quran_memorization_helper/quran_data/ayat.dart';
import 'package:quran_memorization_helper/quran_data/para_bounds.dart';

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
      for (final MutashabihaAyat m in mutashabiha!.matches) {
        m.text = getAyahForIdx(m.ayahIdx, quranTextUtf8).text;
      }
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
  final void Function(int, bool, int) onParaChanged;
  Timer? timer;

  ParaAyatModel(this.onParaChanged);

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
    for (final Ayat a in ayahs) {
      bool wasMutashabiha = false;
      for (final Mutashabiha m in allParaMutashabihas) {
        // can load multiple for same ayah
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
        for (final int w in first.markedWords) {
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

    // validate and add
    for (final Ayat a in newAyahs) {
      if (ayahBelongsToPara(a.ayahIdx, currentPara - 1)) {
        existingAyahs.add(Ayat(a.text, [...a.markedWords], ayahIdx: a.ayahIdx));
      } else {
        int p = paraForAyah(a.ayahIdx) + 1;
        // ignore: avoid_print
        print("Invalid ayah addition, for different para $currentPara vs $p");
      }
    }

    existingAyahs.sort((Ayat a, Ayat b) {
      return a.ayahIdx - b.ayahIdx;
    });

    _paraAyats[para] = existingAyahs;
    persist();
  }

  void setCurrentPara(int para,
      {bool showLastPage = false, int jumpToPage = -1}) {
    if (para == currentPara) return;
    // wrap around
    if (para <= 0) {
      para = 30;
    } else if (para > 30) {
      para = 1;
    }

    onParaChanged(para, showLastPage, jumpToPage);

    currentParaNotifier.value = para;
    notifyListeners();

    // trigger a save
    persist();
  }

  int markedAyahCountForPara(int paraIdx) {
    return _paraAyats[paraIdx + 1]?.length ?? 0;
  }

  void removeAyahs(List<int> ayahsToRemove) {
    final List<Ayat>? list = _paraAyats[currentPara];
    if (list == null) return;
    list.removeWhere((final Ayat ayah) => ayahsToRemove.contains(ayah.ayahIdx));
    _paraAyats[currentPara] = list;
    notifyListeners();
    persist();
  }

  /// Remove ayats from given para index
  void removeMarkedWordInAyat(
      int paraIndex, int absoluteAyahIndex, int wordIndex) {
    final List<Ayat>? ayahs = _paraAyats[paraIndex + 1];
    if (ayahs == null) return;

    for (final (int i, Ayat a) in ayahs.indexed) {
      if (a.ayahIdx == absoluteAyahIndex) {
        if (a.markedWords.remove(wordIndex)) {
          if (a.markedWords.isEmpty) {
            ayahs.removeAt(i);
            break;
          }
        }
      }
    }

    _paraAyats[paraIndex + 1] = ayahs;
    notifyListeners();
    persist();
  }

  void merge(Map<int, List<Ayat>> paraAyahs) {
    for (final MapEntry<int, List<Ayat>> e in paraAyahs.entries) {
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
          for (final a in ayahJsons) {
            try {
              final int idx = a['idx'];
              if (!ayahBelongsToPara(idx, para - 1)) {
                continue;
              }

              final wordIdxes = <int>[for (final w in a['words']) w as int];
              paraData.add(Ayat("", wordIdxes, ayahIdx: idx));
            } catch (_) {
              continue;
            }
          }
        }

        if (paraData.isEmpty) continue;
        paraData.sort((Ayat a, Ayat b) {
          return a.ayahIdx - b.ayahIdx;
        });

        paraAyats[para] = paraData;
      }
    } catch (e) {
      rethrow;
    }

    _paraAyats = paraAyats;
    currentParaNotifier.value = json["currentPara"] ?? 1;
    notifyListeners();
  }

  Future<(bool, Object?)> readJsonDB({String? path}) async {
    try {
      final Map<String, dynamic> json = path == null
          ? await utils.readJsonFile("ayatsdb")
          : await utils.readJsonFromFilePath(path);
      await _resetfromJson(json);
      return (true, null);
    } catch (e) {
      return (false, e);
    }
  }

  Future<String> saveToDisk({String? fileName}) async {
    String path =
        await utils.saveJsonToDisk(jsonStringify(), fileName ?? "ayatsdb");
    return path;
  }

  String jsonStringify() =>
      const JsonEncoder.withIndent("  ").convert(toJson());

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    for (final MapEntry<int, List<Ayat>> kv in _paraAyats.entries) {
      final ayats = <Ayat>[for (final Ayat a in kv.value) a];
      json[kv.key.toString()] = <String, List<Ayat>>{'ayats': ayats};
    }
    json["currentPara"] = currentParaNotifier.value;
    return json;
  }
}
