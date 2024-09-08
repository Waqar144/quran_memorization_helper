import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/models/ayat.dart';
import 'package:quran_memorization_helper/quran_data/pages.dart';
import 'package:quran_memorization_helper/quran_data/para_bounds.dart';
import 'package:quran_memorization_helper/utils/utils.dart';

class ParaListView extends StatelessWidget {
  final int currentParaIdx;
  final void Function(int) onParaTapped;
  final ParaAyatModel model;
  const ParaListView(
      {required this.model,
      required this.currentParaIdx,
      required this.onParaTapped,
      super.key});

  Widget paraListItem(int index, BuildContext context) {
    int count = model.markedAyahCountForPara(index);

    return Directionality(
        textDirection: TextDirection.rtl,
        child: ListTile(
          minVerticalPadding: 0,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15),
          visualDensity: VisualDensity.compact,
          title: Text(
            getParaNameForIndex(index),
            style: const TextStyle(
              letterSpacing: 0,
              fontSize: 26,
              fontFamily: 'Al Mushaf',
            ),
          ),
          leading: Text(
            "${toUrduNumber(index + 1)}$urduKhatma",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontFamily: "Urdu",
                fontSize: 22,
                letterSpacing: 0.0),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                count > 0 ? "$count" : " ",
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
              const SizedBox(width: 5),
              SizedBox(
                  width: 30,
                  child: Text(
                    "${para16LinePageOffsets[index] + 1}",
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyMedium?.color),
                  )),
            ],
          ),
          onTap: () => onParaTapped(index),
          selected: currentParaIdx == index,
          selectedTileColor: Theme.of(context).highlightColor,
        ));
  }

  @override
  Widget build(BuildContext context) {
    int maxVisibleItems =
        ((MediaQuery.of(context).size.height - (48 + 4)) / 48).floor();
    const totalParas = 30;
    final maxScrollablePara = totalParas -
        maxVisibleItems; // if we scroll to the bottom, this para is visible at top

    int paraScrollTo = 0;
    if (currentParaIdx > 8 && currentParaIdx < 20) {
      paraScrollTo = 48 * (currentParaIdx - 3);
    } else if (currentParaIdx > maxScrollablePara) {
      paraScrollTo = 48 * maxScrollablePara;
    }

    final paraListScrollController = ScrollController(
        initialScrollOffset: paraScrollTo.toDouble(), keepScrollOffset: false);

    return ListView.builder(
      controller: paraListScrollController,
      scrollDirection: Axis.vertical,
      itemCount: 30,
      itemExtent: 48,
      itemBuilder: (context, index) {
        return paraListItem(index, context);
      },
    );
  }
}
