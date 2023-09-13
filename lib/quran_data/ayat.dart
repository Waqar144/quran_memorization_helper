import 'surahs.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'ayah_offsets.dart';
import 'para_bounds.dart';
import 'package:flutter/services.dart' show rootBundle;

class Ayat {
  Ayat(this.text, this.markedWords, {required this.ayahIdx});
  List<int> markedWords;
  String text = "";
  final int ayahIdx;
  bool? selected;

  @override
  bool operator ==(Object other) {
    return (other is Ayat) && other.ayahIdx == ayahIdx;
  }

  dynamic toJson() {
    return {
      'idx': ayahIdx,
      'words': markedWords,
    };
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
  final List<int> surahAyahIndexes;
  final int paraIdx;
  final int surahIdx;
  MutashabihaAyat(this.paraIdx, this.surahIdx, this.surahAyahIndexes,
      super.text, super.markedWords,
      {required super.ayahIdx});

  String surahAyahIndexesString() {
    return surahAyahIndexes.fold("", (String s, int v) {
      return s.isEmpty ? "${v + 1}" : "$s, ${v + 1}";
    });
  }

  void loadText(final ByteBuffer quranTextUtf8) {
    if (text.isNotEmpty) return;
    for (final a in surahAyahIndexes) {
      final absIdx = toAbsoluteAyahOffset(surahIdx, a);
      text += getAyahForIdx(absIdx, quranTextUtf8).text;
      if (a != surahAyahIndexes.last) {
        text += ayahSeparator;
      }
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return surahAyahIndexes.length == 1
        ? {'ayah': ayahIdx}
        : {
            'ayah': surahAyahIndexes
                .map((ayahIdx) => toSurahAyahOffset(surahIdx, ayahIdx))
                .toList()
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
      'muts': matches.map((m) => m.toJson()).toList()
    };
  }

  void loadText(final ByteBuffer quranTextUtf8) {
    if (src.text.isEmpty) {
      src.loadText(quranTextUtf8);
      for (int j = 0; j < matches.length; ++j) {
        final match = matches[j];
        match.loadText(quranTextUtf8);
        matches[j] = match;
      }
    }
  }

  @override
  int get hashCode => src.ayahIdx.hashCode;
}

String _getContext(int ayahIdx, String text, final ByteBuffer quranTextUtf8) {
  final range = getAyahRange(ayahIdx + 1);
  String nextAyahText =
      utf8.decode(quranTextUtf8.asUint8List(range.start, range.len)).trim();
  final words = nextAyahText.split(' ');
  List<String> toshow = [];
  for (final word in words) {
    toshow.add(word);
    if (toshow.length > 5) {
      break;
    }
  }
  final String threeDot = toshow.length == words.length ? "" : "...";
  return "$text$ayahSeparator${toshow.join(' ')}$threeDot";
}

MutashabihaAyat ayatFromJsonObj(
    dynamic m, final ByteBuffer? quranTextUtf8, int ctx) {
  try {
    List<int> ayahIdxes;
    if (m["ayah"] is List) {
      ayahIdxes = [for (final a in m["ayah"]) a as int];
    } else {
      ayahIdxes = [m["ayah"] as int];
    }
    String text = "";
    List<int> surahAyahIdxes = [];
    int surahIdx = -1;
    int paraIdx = -1;
    for (final ayahIdx in ayahIdxes) {
      if (quranTextUtf8 != null) {
        final ayahRange = getAyahRange(ayahIdx);
        final textUtf8 =
            quranTextUtf8.asUint8List(ayahRange.start, ayahRange.len);
        text += utf8.decode(textUtf8).trim();
        if (ayahIdx != ayahIdxes.last) {
          text += ayahSeparator;
        }
      }
      if (surahIdx == -1) {
        surahIdx = surahForAyah(ayahIdx);
        paraIdx = paraForAyah(ayahIdx);
      }
      surahAyahIdxes.add(toSurahAyahOffset(surahIdx, ayahIdx));
    }

    final bool showContext = ctx != 0;
    if (showContext && quranTextUtf8 != null) {
      text = _getContext(ayahIdxes.last, text, quranTextUtf8);
    }
    return MutashabihaAyat(paraIdx, surahIdx, surahAyahIdxes, text, [],
        ayahIdx: ayahIdxes.first);
  } catch (e) {
    // print(e);
    rethrow;
  }
}

Future<List<Mutashabiha>> importParaMutashabihas(
    int paraIdx, final ByteBuffer? quranTextUtf8) async {
  final mutashabihasJsonBytes =
      await rootBundle.load("assets/mutashabiha_data.json");
  final mutashabihasJson =
      utf8.decode(mutashabihasJsonBytes.buffer.asUint8List());
  final map = jsonDecode(mutashabihasJson) as Map<String, dynamic>;
  int paraNum = paraIdx + 1;
  final list = map[paraNum.toString()] as List<dynamic>;

  List<Mutashabiha> mutashabihas = [];
  for (final m in list) {
    if (m == null) continue;
    try {
      int ctx = (m["ctx"] as int?) ?? 0;
      MutashabihaAyat src = ayatFromJsonObj(m["src"], quranTextUtf8, ctx);
      List<MutashabihaAyat> matches = [];
      for (final match in m["muts"]) {
        matches.add(ayatFromJsonObj(match, quranTextUtf8, ctx));
      }
      mutashabihas.add(Mutashabiha(src, matches));
    } catch (e) {
      rethrow;
    }
  }
  return mutashabihas;
}
