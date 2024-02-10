import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/models/ayat.dart';
import 'package:quran_memorization_helper/quran_data/para_bounds.dart';

class ParaListView extends StatelessWidget {
  final int currentParaIdx;
  final void Function(int) onParaTapped;
  final ParaAyatModel model;
  const ParaListView(
      {required this.model,
      required this.currentParaIdx,
      required this.onParaTapped,
      super.key});

  Widget paraListItem(int index, BuildContext ctx) {
    int count = model.markedAyahCountForPara(index);
    return ListTile(
      minVerticalPadding: 0,
      visualDensity: VisualDensity.compact,
      title: Text(
        getParaNameForIndex(index),
        style: const TextStyle(
          letterSpacing: 0,
          fontSize: 24,
          fontFamily: 'Al Mushaf',
        ),
      ),
      leading: Text(
        "${index + 1}.",
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 20),
      ),
      trailing: Text(
        count > 0 ? "$count" : "",
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16, color: Colors.red),
      ),
      onTap: () => onParaTapped(index),
      selected: currentParaIdx == index,
      selectedTileColor: Theme.of(ctx).highlightColor,
    );
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
