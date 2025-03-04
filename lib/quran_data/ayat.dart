import 'package:quran_memorization_helper/quran_data/quran_text.dart';

import 'surahs.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'para_bounds.dart';
import 'package:flutter/services.dart' show rootBundle;

class Ayat {
  Ayat(this.text, this.markedWords, {required this.ayahIdx});
  List<int> markedWords;
  String text = "";
  final int ayahIdx;

  @override
  bool operator ==(Object other) {
    return (other is Ayat) && other.ayahIdx == ayahIdx;
  }

  dynamic toJson() {
    return {'idx': ayahIdx, 'words': markedWords};
  }

  /// returns "SurahName":AyahNumInSurah
  String surahAyahText() {
    int surah = surahForAyah(ayahIdx);
    int ayah = toSurahAyahOffset(surah, ayahIdx);
    return "${surahNameForIdx(surah)}:${ayah + 1}";
  }

  @override
  int get hashCode => ayahIdx.hashCode;
}

/// Represent an ayat in a "Mutashabiha"
class MutashabihaAyat extends Ayat {
  final int surahIdx;
  final Uint16List surahAyahIndexes;
  MutashabihaAyat(
    this.surahIdx,
    this.surahAyahIndexes,
    super.text,
    super.markedWords, {
    required super.ayahIdx,
  });

  String surahAyahIndexesString() {
    return surahAyahIndexes.fold("", (String s, int v) {
      return s.isEmpty ? "${v + 1}" : "$s, ${v + 1}";
    });
  }

  int paraNumber() {
    int ayah = toAbsoluteAyahOffset(surahIdx, surahAyahIndexes.first);
    return paraForAyah(ayah) + 1;
  }

  @override
  Map<String, dynamic> toJson() {
    return surahAyahIndexes.length == 1
        ? {'ayah': ayahIdx}
        : {
          'ayah':
              surahAyahIndexes
                  .map((ayahIdx) => toSurahAyahOffset(surahIdx, ayahIdx))
                  .toList(),
        };
  }
}

/// Represents a Mutashabiha
class Mutashabiha {
  final MutashabihaAyat src;
  final List<MutashabihaAyat> matches;
  Mutashabiha(this.src, this.matches);

  @override
  bool operator ==(Object other) {
    return (other is Mutashabiha) && other.src.ayahIdx == src.ayahIdx;
  }

  dynamic toJson() {
    return {
      'src': src.toJson(),
      'muts': matches.map((m) => m.toJson()).toList(),
    };
  }

  void loadText() {
    if (src.text.isEmpty) {
      src.text = QuranText.instance.ayahText(src.ayahIdx);
    }
    for (final MutashabihaAyat m in matches) {
      if (m.text.isEmpty) {
        m.text = QuranText.instance.ayahText(m.ayahIdx);
      }
    }
  }

  @override
  int get hashCode => src.ayahIdx.hashCode;
}

String _getContext(int ayahIdx, String text) {
  final words = QuranText.instance.ayahText(ayahIdx + 1).split('\u200c');
  final firstFive = words.take(5);
  final String threeDot = firstFive.length == words.length ? "" : "...";
  return "$text$ayahSeparator${firstFive.join(' ')}$threeDot";
}

MutashabihaAyat ayatFromJsonObj(dynamic m, int ctx) {
  try {
    List<int> ayahIdxes;
    if (m["ayah"] is List) {
      ayahIdxes = <int>[for (final a in m["ayah"]) a as int];
    } else {
      ayahIdxes = <int>[m["ayah"] as int];
    }
    String text = "";
    final List<int> surahAyahIdxes = [];
    int surahIdx = -1;
    final bool quranTextIsReady = QuranText.instance.isReady;
    for (final int ayahIdx in ayahIdxes) {
      if (quranTextIsReady) {
        text += QuranText.instance.ayahText(ayahIdx);
        if (ayahIdx != ayahIdxes.last) {
          text += ayahSeparator;
        }
      }

      if (surahIdx == -1) {
        surahIdx = surahForAyah(ayahIdx);
      }
      surahAyahIdxes.add(toSurahAyahOffset(surahIdx, ayahIdx));
    }

    final bool showContext = ctx != 0;
    if (showContext && quranTextIsReady) {
      text = _getContext(ayahIdxes.last, text);
    }
    return MutashabihaAyat(
      surahIdx,
      Uint16List.fromList(surahAyahIdxes),
      text,
      [],
      ayahIdx: ayahIdxes.first,
    );
  } catch (e) {
    // print(e);
    rethrow;
  }
}

Future<List<Mutashabiha>> importParaMutashabihas(int paraIdx) async {
  final mutashabihasJsonBytes = await rootBundle.load(
    "assets/mutashabiha_data.json",
  );
  final mutashabihasJson = utf8.decode(
    mutashabihasJsonBytes.buffer.asUint8List(),
  );
  final map = jsonDecode(mutashabihasJson) as Map<String, dynamic>;
  int paraNum = paraIdx + 1;
  final list = map[paraNum.toString()] as List<dynamic>;

  List<Mutashabiha> mutashabihas = [];
  for (final m in list) {
    if (m == null) continue;
    try {
      int ctx = (m["ctx"] as int?) ?? 0;
      MutashabihaAyat src = ayatFromJsonObj(m["src"], ctx);
      List<MutashabihaAyat> matches = [];
      for (final match in m["muts"]) {
        matches.add(ayatFromJsonObj(match, ctx));
      }
      mutashabihas.add(Mutashabiha(src, matches));
    } catch (e) {
      rethrow;
    }
  }
  return mutashabihas;
}
