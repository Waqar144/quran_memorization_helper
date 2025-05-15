import 'package:flutter/foundation.dart';
import 'package:quran_memorization_helper/quran_data/quran_text.dart';
import 'dart:convert';
import 'dart:async';

import 'package:quran_memorization_helper/utils/utils.dart' as utils;
import 'package:quran_memorization_helper/quran_data/ayat.dart';
import 'package:quran_memorization_helper/quran_data/para_bounds.dart';

/// Represents an item that is shown in main page ayah list
class AyatOrMutashabiha {
  final Ayat? ayat;
  final Mutashabiha? mutashabiha;
  const AyatOrMutashabiha({this.ayat, this.mutashabiha});

  void ensureTextIsLoaded() {
    if (ayat != null) {
      ayat!.text = QuranText.instance.ayahText(ayat!.ayahIdx);
    } else if (mutashabiha != null) {
      mutashabiha!.loadText();
    }
  }
}

class ParaAyatModel extends ChangeNotifier {
  // ignore: constant_identifier_names
  static const int VERSION = 1;
  List<Ayat> _ayats = [];
  Timer? timer;

  ParaAyatModel();

  @override
  void dispose() async {
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

  // Only for testing,
  List<Ayat> get ayahs => _ayats;

  List<AyatOrMutashabiha> ayahsAndMutashabihasList(
    int paraNumber,
    List<Mutashabiha> allParaMutashabihas,
  ) {
    if (paraNumber < 1 || paraNumber > 30) {
      return [];
    }

    List<AyatOrMutashabiha> list = [];
    int paraIdx = paraNumber - 1;

    final paraAyahs = _ayats.where(
      (a) => ayahBelongsToPara(a.ayahIdx, paraIdx),
    );

    for (final Ayat a in paraAyahs) {
      bool wasMutashabiha = false;
      for (final Mutashabiha m in allParaMutashabihas) {
        // can load multiple for same ayah
        if (m.src.ayahIdx == a.ayahIdx) {
          m.src.markedWords = [...a.markedWords];
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

  void addAyahs(List<Ayat> newAyahs) {
    if (newAyahs.isEmpty) return;

    Ayat first = newAyahs.first;
    for (final a in _ayats) {
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
      if (a.ayahIdx < 0 || a.ayahIdx > 6236) continue;
      _ayats.add(a);
    }

    _ayats.sort((Ayat a, Ayat b) {
      return a.ayahIdx - b.ayahIdx;
    });

    notifyListeners();
    persist();
  }

  List<int> markedAyahCountsByPara() {
    final List<int> countByPara = List.filled(30, 0);
    for (final a in _ayats) {
      countByPara[paraForAyah(a.ayahIdx)] += 1;
    }
    return countByPara;
  }

  void removeAyahs(List<int> ayahsToRemove) {
    _ayats.removeWhere((ayah) => ayahsToRemove.contains(ayah.ayahIdx));
    notifyListeners();
    persist();
  }

  /// Remove ayats from given para index
  void removeMarkedWordInAyat(int absoluteAyahIndex, int wordIndex) {
    final i = binarySearch(_ayats, absoluteAyahIndex);
    if (i == -1) {
      return;
    }

    final a = _ayats[i];
    assert(a.ayahIdx == absoluteAyahIndex);
    if (a.markedWords.remove(wordIndex)) {
      if (a.markedWords.isEmpty) {
        _ayats.removeAt(i);
      }
    }

    notifyListeners();
    persist();
  }

  Ayat? getAyahInDB(int ayahIdx) {
    final i = binarySearch(_ayats, ayahIdx);
    return i == -1 ? null : _ayats[i];
  }

  static int binarySearch(List<Ayat> sortedList, int ayahIndex) {
    int min = 0;
    int max = sortedList.length;
    while (min < max) {
      final int mid = min + ((max - min) >> 1);
      final ayah = sortedList[mid];
      final int comp = ayah.ayahIdx - ayahIndex;
      if (comp == 0) {
        return mid;
      }
      if (comp < 0) {
        min = mid + 1;
      } else {
        max = mid;
      }
    }
    return -1;
  }

  void merge(List<Ayat> ayahs) {
    ayahs.sort((a, b) => a.ayahIdx - b.ayahIdx);
    addAyahs(ayahs);
  }

  Future<void> _resetfromJson(Map<String, dynamic> json) async {
    final Map<int, List<Ayat>> paraAyats = {};
    _ayats = [];
    try {
      // first version
      if (json['version'] == null) {
        for (final MapEntry<String, dynamic> entry in json.entries) {
          final int? para = int.tryParse(entry.key);
          if (para == null || para > 30 || para < 1) continue;

          final paraJson = entry.value as Map<String, dynamic>;
          List<Ayat> paraData = [];

          var ayahJsons = paraJson["ayats"] as List<dynamic>?;
          if (ayahJsons != null) {
            for (final a in ayahJsons) {
              try {
                final idx = a['idx'] as int;
                if (!ayahBelongsToPara(idx, para - 1)) {
                  continue;
                }

                final wordIdxes = <int>[
                  for (final w in a['words'] as List<dynamic>) w as int,
                ];
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

        for (final e in paraAyats.values) {
          _ayats.addAll(e);
        }
      }
      // VERSION 1
      else if (json['version'] == 1) {
        for (final a in (json['ayats'] as List? ?? [])) {
          final idx = a['idx'] as int;
          final wordIdxes = <int>[
            for (final w in a['words'] as List<dynamic>) w as int,
          ];
          _ayats.add(Ayat("", wordIdxes, ayahIdx: idx));
        }
      }
    } catch (e) {
      rethrow;
    }

    _ayats.sort((a, b) => a.ayahIdx - b.ayahIdx);
    notifyListeners();
  }

  Future<(bool, Object?)> readJsonDB({String? path}) async {
    try {
      final Map<String, dynamic> json =
          path == null
              ? await utils.readJsonFile("ayatsdb")
              : await utils.readJsonFromFilePath(path);
      await _resetfromJson(json);
      return (true, null);
    } catch (e) {
      return (false, e);
    }
  }

  Future<String> saveToDisk({String? fileName}) async {
    String path = await utils.saveJsonToDisk(
      jsonStringify(),
      fileName ?? "ayatsdb",
    );
    return path;
  }

  String jsonStringify() =>
      const JsonEncoder.withIndent("  ").convert(toJson());

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json["ayats"] = _ayats;
    json["version"] = VERSION;
    return json;
  }
}
