import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/quran_data/surahs.dart';
import 'package:quran_memorization_helper/quran_data/pages.dart';
import 'package:quran_memorization_helper/utils/utils.dart';

var lastSurah = 0;
var lastScrollPosition = 0.0;

class SurahListView extends StatelessWidget {
  final int currentParaIdx;
  final int currentPageInPara;
  final void Function(int) onSurahTapped;
  const SurahListView(
      {required this.currentParaIdx,
      required this.currentPageInPara,
      required this.onSurahTapped,
      super.key});

  @override
  Widget build(BuildContext context) {
    int currentPage = currentPageInPara + para16LinePageOffsets[currentParaIdx];
    int currentSurah = surahForPage(currentPage);
    double surahScrollTo = lastScrollPosition > 0.0 && lastSurah == currentSurah
        ? lastScrollPosition
        : 48 * currentSurah.toDouble();
    final surahListScrollController = ScrollController(
        initialScrollOffset: surahScrollTo, keepScrollOffset: false);
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
                "${toUrduNumber(index + 1)}$urduKhatma",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontFamily: "Urdu",
                    fontSize: 22,
                    letterSpacing: 0.0),
              ),
              title: Text(
                surahDataForIdx(index, arabic: true).name,
                style: const TextStyle(
                  letterSpacing: 0,
                  fontSize: 26,
                  fontFamily: 'Al Mushaf',
                ),
              ),
              trailing: Text(
                "${surah16LinePageOffset[index] + 1}",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyMedium?.color),
              ),
              selected: currentSurah == index,
              selectedTileColor: Theme.of(context).highlightColor,
              onTap: () => onSurahTapped(index),
            ));
      },
    );
  }
}
