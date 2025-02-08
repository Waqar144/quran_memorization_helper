import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/models/ayah_selection_model.dart';
import 'package:quran_memorization_helper/models/ayat.dart';
import 'ayat_list_item.dart';
import 'mutashabiha_ayat_list_item.dart';

class AyatAndMutashabihaListView extends StatelessWidget {
  const AyatAndMutashabihaListView(this._ayatsList,
      {super.key,
      required this.onLongPress,
      required this.onTap,
      required this.selectionState,
      this.selectionMode = false});

  final List<AyatOrMutashabiha> _ayatsList;
  final VoidCallback onLongPress;
  final Function(int) onTap;
  final bool selectionMode;
  final AyahSelectionState selectionState;

  Widget _listItemForIndex(int index) {
    if (_ayatsList[index].ayat != null) {
      final ayat = _ayatsList[index].ayat!;
      return AyatListItem(
        key: ObjectKey(ayat),
        ayah: ayat,
        onLongPress: onLongPress,
        onTap: () => onTap(ayat.ayahIdx),
        selectionMode: selectionMode,
        isSelected: selectionState.isSelected(index),
      );
    } else {
      final mutashabiha = _ayatsList[index].mutashabiha!;
      return MutashabihaAyatListItem(
        key: ObjectKey(mutashabiha),
        mutashabiha: mutashabiha,
        onLongPress: onLongPress,
        onTap: () => onTap(mutashabiha.src.ayahIdx),
        selectionMode: selectionMode,
        isSelected: selectionState.isSelected(index),
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
