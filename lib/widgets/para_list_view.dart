import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/models/ayat.dart';
import 'package:quran_memorization_helper/models/settings.dart';
import 'package:quran_memorization_helper/quran_data/para_bounds.dart';
import 'package:quran_memorization_helper/utils/utils.dart';

int lastPara = 0;
double? lastScrollPosition;

class ParaListView extends StatelessWidget {
  final int currentParaIdx;
  final void Function(int) onParaTapped;
  final ParaAyatModel model;
  const ParaListView({
    required this.model,
    required this.currentParaIdx,
    required this.onParaTapped,
    super.key,
  });

  double _getInitialScrollPosition(BuildContext context) {
    if (lastScrollPosition != null && lastPara == currentParaIdx) {
      return lastScrollPosition!;
    }

    int maxVisibleItems =
        ((MediaQuery.sizeOf(context).height - (48 + 4)) / 48).floor();
    const totalParas = 30;
    final maxScrollablePara =
        totalParas -
        maxVisibleItems; // if we scroll to the bottom, this para is visible at top

    int paraScrollTo = 0;
    if (currentParaIdx > 8 && currentParaIdx < 20) {
      paraScrollTo = 48 * (currentParaIdx - 3);
    } else if (currentParaIdx > maxScrollablePara) {
      paraScrollTo = 48 * maxScrollablePara;
    }
    return paraScrollTo.toDouble();
  }

  Widget paraListItem(int index, int count, BuildContext context) {
    final isIndoPk = isIndoPak(Settings.instance.mushaf);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListTile(
        minVerticalPadding: 0,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15),
        visualDensity: VisualDensity.compact,
        title: Text(
          isIndoPk ? getParaNameForIndex(index) : "Juz ${index + 1}",
          style:
              isIndoPk
                  ? TextStyle(
                    letterSpacing: 0,
                    fontSize: 22,
                    fontFamily: getQuranFont(),
                  )
                  : null,
        ),
        leading:
            isIndoPk
                ? Text(
                  "${toUrduNumber(index + 1)}$urduKhatma",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontFamily: "Urdu",
                    fontSize: 22,
                    letterSpacing: 0.0,
                  ),
                )
                : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              count > 0 ? "$count" : " ",
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
          ],
        ),
        onTap: () => onParaTapped(index),
        selected: currentParaIdx == index,
        selectedTileColor: Theme.of(context).highlightColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paraListScrollController = ScrollController(
      initialScrollOffset: _getInitialScrollPosition(context),
      keepScrollOffset: false,
    );
    paraListScrollController.addListener(() {
      lastScrollPosition = paraListScrollController.offset;
    });
    lastPara = currentParaIdx;
    final counts = model.markedAyahCountsByPara();

    return ListView.builder(
      key: const PageStorageKey("para_list_view"),
      controller: paraListScrollController,
      scrollDirection: Axis.vertical,
      itemCount: 30,
      itemExtent: 48,
      itemBuilder: (context, index) {
        return paraListItem(index, counts[index], context);
      },
    );
  }
}
