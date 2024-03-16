import 'dart:typed_data';

class ParaBounds {
  final int start;
  final int end;
  const ParaBounds(this.start, this.end);
}

const String ayahSeparator = " ۞ ";

/// Returns the para idx for given ayah idx
int paraForAyah(int absoluteAyah) {
  for (int i = 0; i < _paraAyahOffset.length; ++i) {
    if (absoluteAyah >= _paraAyahOffset[i]) continue;
    return i - 1;
  }
  // last para
  return 29;
}

bool ayahBelongsToPara(int absoluteAyah, int paraIdx) {
  if (paraIdx < 0 || paraIdx > 29) return false;
  int s = _paraAyahOffset[paraIdx];
  int e = s + paraAyahCount[paraIdx];
  return s <= absoluteAyah && absoluteAyah < e;
}

int getFirstAyahOfPara(int paraIndex) {
  if (paraIndex < 0 || paraIndex > 29) throw "Invalid paraIndex: $paraIndex";
  return _paraAyahOffset[paraIndex];
}

String getParaNameForIndex(int paraIdx) {
  return switch (paraIdx) {
    /* ltr */ 0 => "آلم",
    /* ltr */ 1 => "سَيَقُولُ",
    /* ltr */ 2 => "تِلْكَ الرُّسُلُ",
    /* ltr */ 3 => "لَنْ تَنَالُوا",
    /* ltr */ 4 => "وَالْمُحْصَنَاتُ",
    /* ltr */ 5 => "لَا يُحِبُّ اللَّهُ",
    /* ltr */ 6 => "وَإِذَا سَمِعُوا",
    /* ltr */ 7 => "وَلَوْ أَنَّنَا",
    /* ltr */ 8 => "قَالَ الْمَلَأُ",
    /* ltr */ 9 => "وَاعْلَمُوا",
    /* ltr */ 10 => "يَعْتَذِرُونَ",
    /* ltr */ 11 => "وَمَا مِنْ دَابَّةٍ",
    /* ltr */ 12 => "وَمَا أُبَرِّئُ",
    /* ltr */ 13 => "رُبَمَا",
    /* ltr */ 14 => "سُبْحَانَ الَّذِي",
    /* ltr */ 15 => "قَالَ أَلَمْ",
    /* ltr */ 16 => "اقْتَرَبَ",
    /* ltr */ 17 => "قَدْ أَفْلَحَ",
    /* ltr */ 18 => "وَقَالَ الَّذِينَ",
    /* ltr */ 19 => "أَمَّنْ خَلَقَ",
    /* ltr */ 20 => "اتْلُ مَا أُوحِيَ",
    /* ltr */ 21 => "وَمَنْ يَقْنُتْ",
    /* ltr */ 22 => "وَمَا لِيَ",
    /* ltr */ 23 => "فَمَنْ أَظْلَمُ",
    /* ltr */ 24 => "إِلَيْهِ يُرَدُّ",
    /* ltr */ 25 => "حٰم",
    /* ltr */ 26 => "قَالَ فَمَا خَطْبُكُمْ",
    /* ltr */ 27 => "قَدْ سَمِعَ اللَّهُ",
    /* ltr */ 28 => "تَبَارَكَ الَّذِی",
    /* ltr */ 29 => "عَمَّ",
    _ => throw "Invalid para index: $paraIdx",
  };
}

const List<ParaBounds> paraByteBounds = [
  ParaBounds(0, 24080),
  ParaBounds(24081, 48937),
  ParaBounds(48938, 73433),
  ParaBounds(73434, 97802),
  ParaBounds(97803, 122666),
  ParaBounds(122667, 147323),
  ParaBounds(147324, 173147),
  ParaBounds(173148, 197637),
  ParaBounds(197638, 222064),
  ParaBounds(222065, 245871),
  ParaBounds(245872, 270646),
  ParaBounds(270647, 295598),
  ParaBounds(295599, 320083),
  ParaBounds(320084, 343998),
  ParaBounds(343999, 369288),
  ParaBounds(369289, 394503),
  ParaBounds(394504, 417750),
  ParaBounds(417751, 443310),
  ParaBounds(443311, 469035),
  ParaBounds(469036, 492361),
  ParaBounds(492362, 517038),
  ParaBounds(517039, 541513),
  ParaBounds(541514, 567188),
  ParaBounds(567189, 590887),
  ParaBounds(590888, 616139),
  ParaBounds(616140, 641435),
  ParaBounds(641436, 666396),
  ParaBounds(666397, 691925),
  ParaBounds(691926, 717702),
  ParaBounds(717703, 740472),
];

final Uint32List paraAyahCount = Uint32List.fromList([
  148, // 0
  111, // 1
  125, // 2
  132, // 3
  124, // 4
  111, // 5
  148, // 6
  142, // 7
  159, // 8
  128, // 9
  150, // 10
  170, // 11
  155, // 12
  226, // 13
  185, // 14
  269, // 15
  190, // 16
  202, // 17
  343, // 18
  166, // 19
  179, // 20
  163, // 21
  363, // 22
  175, // 23
  246, // 24
  195, // 25
  399, // 26
  137, // 27
  431, // 28
  564, // 29
]);

final Uint32List _paraAyahOffset = Uint32List.fromList([
  0, // 1
  148, // 2
  259, // 3
  384, // 4
  516, // 5
  640, // 6
  751, // 7
  899, // 8
  1041, // 9
  1200, // 10
  1328, // 11
  1478, // 12
  1648, // 13
  1803, // 14
  2029, // 15
  2214, // 16
  2483, // 17
  2673, // 18
  2875, // 19
  3218, // 20
  3384, // 21
  3563, // 22
  3726, // 23
  4089, // 24
  4264, // 25
  4510, // 26
  4705, // 27
  5104, // 28
  5241, // 29
  5672, // 30
]);
