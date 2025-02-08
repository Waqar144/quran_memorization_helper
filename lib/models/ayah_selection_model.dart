import 'package:quran_memorization_helper/models/ayat.dart';

class AyahSelectionState {
  List<(int ayahIdx, bool selected)> _selection = [];

  AyahSelectionState.fromAyahs(
      final List<AyatOrMutashabiha> ayahAndMutashabihas) {
    _selection = List.generate(ayahAndMutashabihas.length, (index) {
      final a = ayahAndMutashabihas[index];
      return a.ayat != null
          ? (a.ayat!.ayahIdx, false)
          : (a.mutashabiha!.src.ayahIdx, false);
    }, growable: false);
  }

  void toggle(int ayahIndex) {
    int found = _selection.indexWhere((e) => e.$1 == ayahIndex);
    while (found != -1) {
      _selection[found] = (_selection[found].$1, !_selection[found].$2);
      found = _selection.indexWhere((e) => e.$1 == ayahIndex, found + 1);
    }
  }

  void selectAll() {
    if (_selection.isEmpty) return;
    final firstSelected = _selection[0].$2;

    for (int i = 0; i < _selection.length; ++i) {
      _selection[i] = (_selection[i].$1, !firstSelected);
    }
  }

  void clearSelection() {
    for (int i = 0; i < _selection.length; ++i) {
      _selection[i] = (_selection[i].$1, false);
    }
  }

  bool isSelected(int index) {
    return index < _selection.length ? _selection[index].$2 : false;
  }

  List<int> selectedAyahs() {
    List<int> toRemove = [];
    for (final e in _selection) {
      if (!toRemove.contains(e.$1)) toRemove.add(e.$1);
    }
    return toRemove;
  }
}
