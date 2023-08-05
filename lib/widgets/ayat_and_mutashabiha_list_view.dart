import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/models/ayat.dart';
import 'ayat_list_item.dart';
import 'mutashabiha_ayat_list_item.dart';

class AyatAndMutashabihaListView extends StatelessWidget {
  const AyatAndMutashabihaListView(this._ayatsList,
      {super.key, required this.onLongPress, this.selectionMode = false});

  final List<AyatOrMutashabiha> _ayatsList;
  final VoidCallback onLongPress;
  final bool selectionMode;

  Widget _listItemForIndex(int index) {
    if (_ayatsList[index].ayat != null) {
      final ayat = _ayatsList[index].ayat!;
      return AyatListItem(
        key: ObjectKey(ayat),
        ayah: ayat,
        onLongPress: onLongPress,
        selectionMode: selectionMode,
      );
    } else {
      final mutashabiha = _ayatsList[index].mutashabiha!;
      return MutashabihaAyatListItem(
        key: ObjectKey(mutashabiha),
        mutashabiha: mutashabiha,
        onLongPress: onLongPress,
        selectionMode: selectionMode,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      separatorBuilder: (BuildContext context, int index) =>
          const Divider(indent: 8, endIndent: 8, color: Colors.grey, height: 2),
      itemCount: _ayatsList.length,
      itemBuilder: (context, index) {
        return _listItemForIndex(index);
      },
    );
  }
}
