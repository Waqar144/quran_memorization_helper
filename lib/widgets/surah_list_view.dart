import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/quran_data/surahs.dart';
import 'package:quran_memorization_helper/quran_data/pages.dart';
import 'package:quran_memorization_helper/utils/utils.dart';
import 'package:quran_memorization_helper/models/settings.dart';

int lastSurah = 0;
double? lastScrollPosition;

class SurahListView extends StatelessWidget {
  final int currentPage;
  final void Function(int) onSurahTapped;
  const SurahListView({
    required this.currentPage,
    required this.onSurahTapped,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final mushaf = Settings.instance.mushaf;
    final is16line = Settings.instance.mushaf == Mushaf.Indopak16Line;
    final surahList = switch (Settings.instance.mushaf) {
      Mushaf.Indopak16Line => surah16LinePageOffset,
      Mushaf.Uthmani15Line => surah15LinePageOffset,
      Mushaf.Indopak15Line => surah15LineIndopakPageOffset,
      Mushaf.Indopak13Line => surah13LinePageOffset,
    };
    int currentSurah = surahForPage(currentPage, mushaf);
    double surahScrollTo =
        lastScrollPosition != null && lastSurah == currentSurah
            ? lastScrollPosition!
            : 48 * currentSurah.toDouble();
    final surahListScrollController = ScrollController(
      initialScrollOffset: surahScrollTo,
      keepScrollOffset: false,
    );
    surahListScrollController.addListener(() {
      lastScrollPosition = surahListScrollController.offset;
    });
    lastSurah = currentSurah;

    return ListView.builder(
      controller: surahListScrollController,
      scrollDirection: Axis.vertical,
      itemCount: 114,
      itemExtent: 48,
      itemBuilder: (context, index) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 15),
            leading: Text(
              is16line
                  ? "${toUrduNumber(index + 1)}$urduKhatma"
                  : "${toArabicNumber(index + 1)}$urduKhatma",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontFamily: "Urdu",
                fontSize: 22,
                letterSpacing: 0.0,
              ),
            ),
            title: Text(
              String.fromCharCode(surahGlyphCode(index)),
              style: TextStyle(
                letterSpacing: 0,
                fontSize: 28,
                fontFamily: "SurahNames",
              ),
            ),
            trailing: Text(
              "${surahList[index] + 1}",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            selected: currentSurah == index,
            selectedTileColor: Theme.of(context).highlightColor,
            onTap: () => onSurahTapped(index),
          ),
        );
      },
    );
  }
}
