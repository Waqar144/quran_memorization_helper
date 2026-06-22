import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/models/ayat.dart';
import 'package:quran_memorization_helper/models/settings.dart';
import 'package:quran_memorization_helper/quran_data/para_bounds.dart';
import 'package:quran_memorization_helper/utils/utils.dart';

int lastPara = 0;
double? lastScrollPosition;
const double itemHeight = 48.0;

class ParaListView extends StatefulWidget {
  final int currentParaIdx;
  final void Function(int) onParaTapped;
  final ParaAyatModel model;
  const ParaListView({
    required this.model,
    required this.currentParaIdx,
    required this.onParaTapped,
    super.key,
  });

  @override
  State<ParaListView> createState() => _ParaListViewState();
}

class _ParaListViewState extends State<ParaListView> {
  late final ScrollController paraListScrollController;

  @override
  void initState() {
    super.initState();

    paraListScrollController = ScrollController(
      initialScrollOffset: _getInitialScrollPosition(),
      keepScrollOffset: false,
    );
    paraListScrollController.addListener(() {
      lastScrollPosition = paraListScrollController.offset;
    });
    lastPara = widget.currentParaIdx;
  }

  @override
  void dispose() {
    paraListScrollController.dispose();
    super.dispose();
  }

  double _getInitialScrollPosition() {
    if (lastScrollPosition != null && lastPara == widget.currentParaIdx) {
      return lastScrollPosition!;
    }
    return widget.currentParaIdx * itemHeight;
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
        onTap: () => widget.onParaTapped(index),
        selected: widget.currentParaIdx == index,
        selectedTileColor: Theme.of(context).highlightColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final counts = widget.model.markedAyahCountsByPara();

    return ListView.builder(
      key: const PageStorageKey("para_list_view"),
      controller: paraListScrollController,
      scrollDirection: Axis.vertical,
      itemCount: 30,
      itemExtent: itemHeight,
      itemBuilder: (context, index) {
        return paraListItem(index, counts[index], context);
      },
    );
  }
}
