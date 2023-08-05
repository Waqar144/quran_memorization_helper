import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/quran_data/ayat.dart';
import 'package:quran_memorization_helper/widgets/ayat_list_item.dart';

class AyatListView extends StatelessWidget {
  const AyatListView(this._ayatsList,
      {super.key, required this.onLongPress, this.selectionMode = false});

  final List<Ayat> _ayatsList;
  final VoidCallback onLongPress;
  final bool selectionMode;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      separatorBuilder: (BuildContext context, int index) =>
          const Divider(indent: 8, endIndent: 8, color: Colors.grey, height: 2),
      itemCount: _ayatsList.length,
      itemBuilder: (context, index) {
        final ayat = _ayatsList[index];
        return AyatListItem(
            key: ObjectKey(ayat),
            ayah: _ayatsList[index],
            onLongPress: onLongPress,
            selectionMode: selectionMode);
      },
    );
  }
}
