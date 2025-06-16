import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/models/ayat.dart';
import 'package:quran_memorization_helper/models/settings.dart';
import 'package:quran_memorization_helper/quran_data/pages.dart';

class AppBarModel {
  final ParaAyatModel model;
  bool _inLongPress = false;
  Future<void> Function(int page, bool animate) goToPage;

  AppBarModel(this.model, this.goToPage);

  void changeTheme(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      Settings.instance.themeMode = ThemeMode.light;
    } else {
      Settings.instance.themeMode = ThemeMode.dark;
    }
  }

  void toggleBookmark(int page) {
    if (model.bookmarks.contains(page)) {
      model.removeBookmark(page);
    } else {
      model.addBookmark(page);
    }
  }

  void nextPage(int? currentPage) {
    final mushaf = Settings.instance.mushaf;
    int totalPages = pageCount(mushaf);
    int nextPage = (currentPage ?? -1) + 1;
    bool animate = true;
    if (nextPage >= totalPages) {
      nextPage = 0;
      animate = false;
    }
    goToPage(nextPage, animate);
  }

  void previousPage(int? currentPage) {
    int previousPage = (currentPage ?? 1) - 1;
    bool animate = true;
    if (previousPage < 0) {
      animate = false;
      final mushaf = Settings.instance.mushaf;
      previousPage = pageCount(mushaf);
    }
    goToPage(previousPage, animate);
  }

  void nextPara(int currentPage) {
    final mushaf = Settings.instance.mushaf;
    final current = paraForPage(currentPage, mushaf);
    int page = current == 29 ? 0 : paraStartPage(current + 1, mushaf);
    goToPage(page, false);
  }

  void previousPara(int currentPage) {
    final mushaf = Settings.instance.mushaf;
    final current = paraForPage(currentPage, mushaf);
    int juz = current == 0 ? 29 : current - 1;
    int page = paraStartPage(juz, mushaf);
    goToPage(page, false);
  }

  Future<void> longPressFwdBackButton(int currentPage, bool fwd) async {
    _inLongPress = true;
    final mushaf = Settings.instance.mushaf;
    int totalPages = pageCount(mushaf);
    final offset = fwd ? 1 : -1;

    while (currentPage < totalPages && currentPage >= 0) {
      if (_inLongPress == false) break;
      await goToPage(currentPage, true);
      currentPage += offset;
    }
  }

  void arrowButtonTapUp() {
    _inLongPress = false;
  }
}
