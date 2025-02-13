import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/quran_data/ayat.dart';

final markedWordBgColorLight = Colors.red.shade100;
final markedWordBgColorDark = Colors.red.withAlpha(80);
const markedWordFgColor = Colors.red;

/// Returns text spans for ayah where marked words are colored red
List<TextSpan> textSpansForAyah(Ayat ayah) {
  final List<String> words = ayah.text.split("\u200c");
  List<TextSpan> ret = [];
  String currentString = "";

  for (int i = 0; i < words.length; ++i) {
    if (ayah.markedWords.contains(i)) {
      // first add existing string
      if (currentString.isNotEmpty) {
        ret.add(TextSpan(text: currentString));
        currentString = "";
      }
      // now add the span for mistake
      ret.add(TextSpan(
          text: "${words[i]} ",
          style: TextStyle(inherit: true, color: markedWordFgColor)));
    } else {
      currentString += "${words[i]} ";
    }
  }

  if (currentString.isNotEmpty) {
    ret.add(TextSpan(text: currentString));
  }

  return ret;
}
