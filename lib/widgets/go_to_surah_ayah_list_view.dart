import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/quran_data/surahs.dart';
import 'package:quran_memorization_helper/quran_data/pages.dart';
import 'package:quran_memorization_helper/utils/utils.dart';
import 'package:quran_memorization_helper/models/settings.dart';

class GotoSurahAyahListView extends StatefulWidget {
  final int currentPage;
  final void Function(int) onGoToAyah;

  const GotoSurahAyahListView({
    required this.currentPage,
    required this.onGoToAyah,
    super.key,
  });

  @override
  State<GotoSurahAyahListView> createState() => _GotoSurahAyahListViewState();
}

class _GotoSurahAyahListViewState extends State<GotoSurahAyahListView> {
  final currentSelectedSurah = ValueNotifier<int>(0);
  late final FixedExtentScrollController wheelScrollController;
  int currentSelectedSurahAyah = 0;

  @override
  void initState() {
    currentSelectedSurah.value = surahForPage(
      widget.currentPage,
      Settings.instance.mushaf,
    );
    wheelScrollController = FixedExtentScrollController(
      keepScrollOffset: false,
    );
    super.initState();
  }

  @override
  void dispose() {
    wheelScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mushaf = Settings.instance.mushaf;

    return Column(
      children: [
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: currentSelectedSurah,
            builder: (context, value, child) {
              return Row(
                children: [
                  Expanded(child: _buildSurahList(mushaf, value)),
                  Expanded(child: _buildAyahList(value)),
                ],
              );
            },
          ),
        ),
        const Divider(height: 2, thickness: 2),
        SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: ElevatedButton.icon(
              label: Text("Go to ayah"),
              icon: const Icon(Icons.open_in_new),
              onPressed: () {
                int ayahIdx = toAbsoluteAyahOffset(
                  currentSelectedSurah.value,
                  currentSelectedSurahAyah,
                );
                widget.onGoToAyah(ayahIdx);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSurahList(Mushaf mushaf, int currentSurah) {
    final isIndoPk = isIndoPak(mushaf);
    double surahScrollTo = 48 * currentSurah.toDouble();

    return ListView.builder(
      controller: ScrollController(
        initialScrollOffset: surahScrollTo,
        keepScrollOffset: false,
      ),
      scrollDirection: Axis.vertical,
      itemCount: 114,
      itemExtent: 48,
      itemBuilder: (context, index) {
        final surahName =
            isIndoPk
                ? surahDataForIdx(index, arabic: true).name
                : String.fromCharCode(surahGlyphCode(index));
        return Directionality(
          textDirection: TextDirection.rtl,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 15),
            leading: Text(
              isIndoPk
                  ? "${toUrduNumber(index + 1)}$urduKhatma"
                  : "${toArabicNumber(index + 1)}$urduKhatma",
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontFamily: "Urdu",
                fontSize: 22,
                letterSpacing: 0.0,
              ),
            ),
            title: Text(
              surahName,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                letterSpacing: 0,
                fontSize: isIndoPk ? 22 : 28,
                fontFamily: isIndoPk ? getQuranFont() : "SurahNames",
              ),
            ),
            trailing: Text(
              "${surahStartPageNumberUI(index, mushaf)}",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            selected: currentSurah == index,
            selectedTileColor: Theme.of(context).highlightColor,
            onTap: () {
              currentSelectedSurah.value = index;
            },
          ),
        );
      },
    );
  }

  Widget _buildAyahList(int currentSurahIdx) {
    if (wheelScrollController.hasClients) {
      wheelScrollController.jumpToItem(0);
    }

    return AyahScrollWheel(
      ayahCount: surahDataForIdx(currentSurahIdx).ayahCount,
      scrollController: wheelScrollController,
      onSelectedAyahChanged: (ayah) {
        currentSelectedSurahAyah = ayah;
      },
    );
  }
}

class AyahScrollWheel extends StatelessWidget {
  final currentSelectedAyah = ValueNotifier(0);
  final int ayahCount;
  final FixedExtentScrollController scrollController;
  final void Function(int) onSelectedAyahChanged;

  AyahScrollWheel({
    required this.ayahCount,
    required this.scrollController,
    required this.onSelectedAyahChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: currentSelectedAyah,
      builder: (context, value, child) {
        return ListWheelScrollView.useDelegate(
          controller: scrollController,
          itemExtent: 48,
          physics: FixedExtentScrollPhysics(),
          onSelectedItemChanged: (index) {
            currentSelectedAyah.value = index;
            onSelectedAyahChanged(index);
          },
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: ayahCount,
            builder: (context, index) {
              final isSelected = (value == index);
              return ListTile(
                selected: isSelected,
                selectedTileColor: Theme.of(context).hoverColor,
                title: Text("${index + 1}", textAlign: TextAlign.center),
              );
            },
          ),
        );
      },
    );
  }
}
