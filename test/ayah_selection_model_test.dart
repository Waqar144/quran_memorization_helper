import 'package:flutter_test/flutter_test.dart';
import 'package:quran_memorization_helper/models/ayah_selection_model.dart';
import 'package:quran_memorization_helper/quran_data/ayat.dart';
import 'package:quran_memorization_helper/models/ayat.dart';

void main() {
  // rhs is para idx so actual is +1
  test("test AyahSelectionState", () {
    final sel = AyahSelectionState.fromAyahs([
      AyatOrMutashabiha(ayat: Ayat("", [], ayahIdx: 0), mutashabiha: null),
      AyatOrMutashabiha(ayat: Ayat("", [], ayahIdx: 1), mutashabiha: null),
      AyatOrMutashabiha(ayat: Ayat("", [], ayahIdx: 2), mutashabiha: null),
      AyatOrMutashabiha(
          ayat: Ayat("", [], ayahIdx: 2),
          mutashabiha: Mutashabiha(
              MutashabihaAyat(0, 0, <int>[], "", [], ayahIdx: 3), [])),
      AyatOrMutashabiha(
          ayat: Ayat("", [], ayahIdx: 2),
          mutashabiha: Mutashabiha(
              MutashabihaAyat(0, 0, <int>[], "", [], ayahIdx: 3), [])),
    ]);

    sel.toggle(0);
    expect(sel.isSelected(0), true);
    sel.toggle(0);
    expect(sel.isSelected(0), false);

    sel.selectAll();
    expect(sel.isSelected(0), true);
    expect(sel.isSelected(1), true);
    expect(sel.isSelected(2), true);
    expect(sel.isSelected(3), true);
    expect(sel.isSelected(4), true);
    expect(sel.selectedAyahs(), <int>[0, 1, 2]); // uniquified

    sel.clearSelection();
    expect(sel.selectedAyahs(), <int>[]);

    // ignore: avoid_print
    print("test AyahSelectionState OK");
  });
}
