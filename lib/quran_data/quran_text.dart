import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:quran_memorization_helper/models/settings.dart';
import 'package:quran_memorization_helper/utils/utils.dart';

class QuranText {
  static final QuranText _instance = QuranText._private();
  static QuranText get instance => _instance;

  List<String> _ayahs = [];
  bool _isReady = false;

  void loadData(Mushaf fontStyle) async {
    String folder = getQuranTextFolder();
    print("Load folder: $folder");

    _ayahs = List.filled(6236, "", growable: false);

    // final sw = Stopwatch()..start();

    for (int i = 1; i <= 30; ++i) {
      final data = await rootBundle.loadString(
        "assets/$folder/$i.json",
        cache: false,
      );
      final json = jsonDecode(data) as List<dynamic>;

      int lastIndex = -1;

      for (final pg in json) {
        final pageObj = pg as Map<String, dynamic>;
        final linesArray = pageObj["lines"] as List<dynamic>;
        for (final line in linesArray) {
          final lineayahs = line as List<dynamic>;
          for (final la in lineayahs) {
            final idx = la["idx"] as int;
            final t = la["text"] as String;
            if (idx == lastIndex) {
              _ayahs[idx] = "${_ayahs[idx]}\u200c$t";
            } else {
              _ayahs[idx] = t;
            }
            lastIndex = idx;
          }
        }
      }
    }

    _isReady = true;
  }

  bool get isReady => _isReady;

  String ayahText(int i) {
    if (!_isReady) return "";
    return _ayahs[i];
  }

  QuranText._private();
}
