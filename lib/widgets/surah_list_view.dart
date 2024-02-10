import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/quran_data/surahs.dart';
import 'package:quran_memorization_helper/quran_data/pages.dart';

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
    int surah = firstSurahInPara(currentParaIdx);
    double surahScrollTo = 48 * surah.toDouble();
    final surahListScrollController = ScrollController(
        initialScrollOffset: surahScrollTo, keepScrollOffset: false);
    int currentPage = currentPageInPara + para16LinePageOffsets[currentParaIdx];
    int currentSurah = surahForPage(currentPage);
    print("Page: $currentPageInPara Current Surah: $currentSurah");

    return ListView.builder(
      controller: surahListScrollController,
      scrollDirection: Axis.vertical,
      itemCount: 114,
      itemExtent: 48,
      itemBuilder: (context, index) {
        return ListTile(
          leading: Text(
            "${index + 1}.",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20),
          ),
          title: Text(
            surahDataForIdx(index, arabic: true).name,
            style: const TextStyle(
              letterSpacing: 0,
              fontSize: 24,
              fontFamily: 'Al Mushaf',
            ),
          ),
          selected: currentSurah == index,
          selectedTileColor: Theme.of(context).highlightColor,
          onTap: () => onSurahTapped(index),
        );
      },
    );
  }
}
