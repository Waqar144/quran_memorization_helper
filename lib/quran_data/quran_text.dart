import 'package:quran_memorization_helper/models/settings.dart';
import 'package:quran_memorization_helper/quran_data/text_indopak.dart';
import 'package:quran_memorization_helper/quran_data/text_uthmani.dart';

class QuranText {
  static final QuranText _instance = QuranText._private();
  static QuranText get instance => _instance;

  List<String> _ayahs = [];

  void loadData(Mushaf mushaf) async {
    _ayahs = switch (mushaf) {
      Mushaf.Indopak13Line ||
      Mushaf.Indopak16Line ||
      Mushaf.Indopak15Line => ayahs16Line,
      Mushaf.Uthmani15Line => ayahs15Line,
    };
    assert(_ayahs.length == 6236, "Ayahs are ${_ayahs.length}");
  }

  String ayahText(int i) {
    return _ayahs[i];
  }

  int ayahCount() => _ayahs.length;

  bool ayahContainsWordIndex(int ayahIndex, int wordIndex) {
    if (ayahIndex < ayahCount() && wordIndex >= 0) {
      final ayah = _ayahs[ayahIndex];
      try {
        return _offsetForWordIdx(ayah, wordIndex) >= 0;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  String spaceSplittedAyahText(int i) {
    return _ayahs[i].splitMapJoin("\u200c", onMatch: (_) => " ");
  }

  int _offsetForWordIdx(String text, int wordIdx) {
    if (wordIdx == 0) return 0;
    int s = text.indexOf("\u200c");
    int i = 1;
    while (s >= 0) {
      if (i == wordIdx) return s;
      s = text.indexOf("\u200c", s + 1);
      i++;
    }
    throw "Word not found!, bug -- $s\n$text\n$wordIdx\n---";
  }

  List<(int, String)> ayahsForRanges(
    int startAyah,
    int startWord,
    int? nextAyah,
    int? nextAyahWord,
  ) {
    List<(int, String)> ret = [];

    if (nextAyah != null) {
      assert(nextAyahWord != null);
      if (startAyah == nextAyah) {
        final text = ayahText(startAyah);
        int s = _offsetForWordIdx(text, startWord);
        int e = _offsetForWordIdx(text, nextAyahWord!);
        // print("return 0 -> ${text.substring(s, e)}");
        return [(startAyah, text.substring(s, e))];
      }

      final text = ayahText(startAyah);
      ret.add((startAyah, text.substring(_offsetForWordIdx(text, startWord))));
      // print("add 0 -> ${text.substring(_offsetForWordIdx(text, startWord))}");
      for (int i = startAyah + 1; i < nextAyah; ++i) {
        final text = ayahText(i);
        ret.add((i, text));
        // print("add i -> $text");
      }
      if (nextAyahWord == 0) {
        return ret;
      }

      final nextText = ayahText(nextAyah);
      ret.add((
        nextAyah,
        nextText.substring(0, _offsetForWordIdx(nextText, nextAyahWord!)),
      ));
      // print(
      //   "add e -> ${nextText.substring(0, _offsetForWordIdx(nextText, nextAyahWord!))}",
      // );
      return ret;
    } else {
      final text = ayahText(startAyah);
      int s = _offsetForWordIdx(text, startWord);
      // print("Final ---> ${text.substring(s)}");
      return [(startAyah, text.substring(s))];
    }
  }

  QuranText._private();
}
