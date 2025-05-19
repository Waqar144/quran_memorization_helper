import 'package:quran_memorization_helper/models/ayat.dart';

class AyahSelectionState {
  final List<({int ayahIdx, bool selected})> _selection;

  AyahSelectionState.fromAyahs(
    final List<AyatOrMutashabiha> ayahAndMutashabihat,
  ) : _selection = List.generate(ayahAndMutashabihat.length, (int index) {
        final AyatOrMutashabiha a = ayahAndMutashabihat[index];
        return a.ayat != null
            ? (ayahIdx: a.ayat!.ayahIdx, selected: false)
            : (ayahIdx: a.mutashabiha!.src.ayahIdx, selected: false);
      }, growable: false);

  void toggle(int ayahIndex) {
    int found = _selection.indexWhere((e) => e.ayahIdx == ayahIndex);
    while (found != -1) {
      _selection[found] = (
        ayahIdx: _selection[found].ayahIdx,
        selected: !_selection[found].selected,
      );
      found = _selection.indexWhere((e) => e.ayahIdx == ayahIndex, found + 1);
    }
  }

  void selectAll() {
    if (_selection.isEmpty) return;
    final bool firstSelected = _selection[0].selected;

    for (int i = 0; i < _selection.length; ++i) {
      _selection[i] = (
        ayahIdx: _selection[i].ayahIdx,
        selected: !firstSelected,
      );
    }
  }

  void clearSelection() {
    for (int i = 0; i < _selection.length; ++i) {
      _selection[i] = (ayahIdx: _selection[i].ayahIdx, selected: false);
    }
  }

  bool isSelected(int index) {
    return index < _selection.length ? _selection[index].selected : false;
  }

  List<int> selectedAyahs() {
    List<int> toRemove = [];
    for (final item in _selection) {
      if (item.selected && !toRemove.contains(item.ayahIdx)) {
        toRemove.add(item.ayahIdx);
      }
    }
    return toRemove;
  }
}
