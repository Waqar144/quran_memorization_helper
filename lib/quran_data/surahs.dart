import 'dart:typed_data';
import 'pages.dart';
import 'package:quran_memorization_helper/models/settings.dart';

int toSurahAyahOffset(int surahIdx, int absoluteAyah) {
  if (surahIdx > _surahAyahOffsets.length) {
    throw "Invalid surah $surahIdx";
  }
  return absoluteAyah - _surahAyahOffsets[surahIdx];
}

int toAbsoluteAyahOffset(int surahIdx, int surahAyahIdx) {
  if (surahIdx > _surahAyahOffsets.length) {
    throw "Invalid surah $surahIdx";
  }
  return _surahAyahOffsets[surahIdx] + surahAyahIdx;
}

int surahForAyah(int absoluteAyah) {
  for (int i = 0; i < _surahAyahOffsets.length; ++i) {
    if (absoluteAyah >= _surahAyahOffsets[i]) {
      continue;
    }
    return i - 1;
  }
  // last surah
  return _surahAyahOffsets.length - 1;
}

class SurahData {
  final String name;
  final int ayahCount;
  const SurahData(this.name, this.ayahCount);
}

String surahNameForIdx(int idx) {
  return surahDataForIdx(idx, arabic: false).name;
}

SurahData surahDataForIdx(int idx, {bool arabic = false}) {
  return switch (idx) {
    0 => SurahData(arabic ? "ٱلْفَاتِحَةُ" : "Al-Fatihah", 7),
    1 => SurahData(arabic ? "ٱلْبَقَرَةُ" : "Al-Baqarah", 286),
    2 => SurahData(arabic ? "آلِ عِمْرَانَ" : "Ali 'Imran", 200),
    3 => SurahData(arabic ? "ٱلنِّسَاءُ" : "An-Nisa", 176),
    4 => SurahData(arabic ? "ٱلْمَائِدَةُ" : "Al-Ma'idah", 120),
    5 => SurahData(arabic ? "ٱلْأَنْعَامُ" : "Al-An'am", 165),
    6 => SurahData(arabic ? "ٱلْأَعْرَافُ" : "Al-A'raf", 206),
    7 => SurahData(arabic ? "ٱلْأَنْفَالُ" : "Al-Anfal", 75),
    8 => SurahData(arabic ? "ٱلتَّوْبَةُ" : "At-Tawbah", 129),
    9 => SurahData(arabic ? "يُونُسَ" : "Yunus", 109),
    10 => SurahData(arabic ? "هُودٌ" : "Hud", 123),
    11 => SurahData(arabic ? "يُوسُفَ" : "Yusuf", 111),
    12 => SurahData(arabic ? "ٱلرَّعْدُ" : "Ar-Ra'd", 43),
    13 => SurahData(arabic ? "إِبْرَٰهِيمَ" : "Ibrahim", 52),
    14 => SurahData(arabic ? "ٱلْحِجْرُ" : "Al-Hijr", 99),
    15 => SurahData(arabic ? "ٱلنَّحْلُ" : "An-Nahl", 128),
    16 => SurahData(arabic ? "ٱلْإِسْرَاءُ" : "Al-Isra", 111),
    17 => SurahData(arabic ? "ٱلْكَهْفُ" : "Al-Kahf", 110),
    18 => SurahData(arabic ? "مَرْيَمَ" : "Maryam", 98),
    19 => SurahData(arabic ? "طه" : "Taha", 135),
    20 => SurahData(arabic ? "ٱلْأَنْبِيَاءُ" : "Al-Anbya", 112),
    21 => SurahData(arabic ? "ٱلْحَجُّ" : "Al-Hajj", 78),
    22 => SurahData(arabic ? "ٱلْمُؤْمِنُونَ" : "Al-Mu'minun", 118),
    23 => SurahData(arabic ? "ٱلنُّورُ" : "An-Nur", 64),
    24 => SurahData(arabic ? "ٱلْفُرْقَانُ" : "Al-Furqan", 77),
    25 => SurahData(arabic ? "ٱلشُّعَرَاءُ" : "Ash-Shu'ara", 227),
    26 => SurahData(arabic ? "ٱلنَّمْلُ" : "An-Naml", 93),
    27 => SurahData(arabic ? "ٱلْقَصَصُ" : "Al-Qasas", 88),
    28 => SurahData(arabic ? "ٱلْعَنْكَبُوتُ" : "Al-'Ankabut", 69),
    29 => SurahData(arabic ? "ٱلرُّومُ" : "Ar-Rum", 60),
    30 => SurahData(arabic ? "لُقْمَانَ" : "Luqman", 34),
    31 => SurahData(arabic ? "ٱلسَّجْدَةُ" : "As-Sajdah", 30),
    32 => SurahData(arabic ? "ٱلْأَحْزَابُ" : "Al-Ahzab", 73),
    33 => SurahData(arabic ? "سَبَأَ" : "Saba", 54),
    34 => SurahData(arabic ? "فَاطِرٌ" : "Fatir", 45),
    35 => SurahData(arabic ? "يسٓ" : "Ya-Sin", 83),
    36 => SurahData(arabic ? "ٱلصَّافَّاتُ" : "As-Saffat", 182),
    37 => SurahData(arabic ? "صٓ" : "Sad", 88),
    38 => SurahData(arabic ? "ٱلزُّمَرُ" : "Az-Zumar", 75),
    39 => SurahData(arabic ? "غَافِرٌ" : "Ghafir", 85),
    40 => SurahData(arabic ? "فُصِّلَتْ" : "Fussilat", 54),
    41 => SurahData(arabic ? "ٱلشُّورَىٰ" : "Ash-Shuraa", 53),
    42 => SurahData(arabic ? "ٱلزُّخْرُفُ" : "Az-Zukhruf", 89),
    43 => SurahData(arabic ? "ٱلدُّخَانُ" : "Ad-Dukhan", 59),
    44 => SurahData(arabic ? "ٱلْجَاثِيَةُ" : "Al-Jathiyah", 37),
    45 => SurahData(arabic ? "ٱلْأَحْقَافُ" : "Al-Ahqaf", 35),
    46 => SurahData(arabic ? "مُحَمَّدٌ" : "Muhammad", 38),
    47 => SurahData(arabic ? "ٱلْفَتْحُ" : "Al-Fath", 29),
    48 => SurahData(arabic ? "ٱلْحُجُرَاتُ" : "Al-Hujurat", 18),
    49 => SurahData(arabic ? "قٓ" : "Qaf", 45),
    50 => SurahData(arabic ? "ٱلذَّارِيَاتُ" : "Adh-Dhariyat", 60),
    51 => SurahData(arabic ? "ٱلطُّورُ" : "At-Tur", 49),
    52 => SurahData(arabic ? "ٱلنَّجْمُ" : "An-Najm", 62),
    53 => SurahData(arabic ? "ٱلْقَمَرُ" : "Al-Qamar", 55),
    54 => SurahData(arabic ? "ٱلرَّحْمَٰنُ" : "Ar-Rahman", 78),
    55 => SurahData(arabic ? "ٱلْوَاقِعَةُ" : "Al-Waqi'ah", 96),
    56 => SurahData(arabic ? "ٱلْحَدِيدُ" : "Al-Hadid", 29),
    57 => SurahData(arabic ? "ٱلْمُجَادِلَةُ" : "Al-Mujadila", 22),
    58 => SurahData(arabic ? "ٱلْحَشْرُ" : "Al-Hashr", 24),
    59 => SurahData(arabic ? "ٱلْمُمْتَحَنَةُ" : "Al-Mumtahanah", 13),
    60 => SurahData(arabic ? "ٱلصَّفُّ" : "As-Saf", 14),
    61 => SurahData(arabic ? "ٱلْجُمُعَةُ" : "Al-Jumu'ah", 11),
    62 => SurahData(arabic ? "ٱلْمُنَافِقُونَ" : "Al-Munafiqun", 11),
    63 => SurahData(arabic ? "ٱلتَّغَابُنُ" : "At-Taghabun", 18),
    64 => SurahData(arabic ? "ٱلطَّلَاقُ" : "At-Talaq", 12),
    65 => SurahData(arabic ? "ٱلتَّحْرِيمُ" : "At-Tahrim", 12),
    66 => SurahData(arabic ? "ٱلْمُلْكُ" : "Al-Mulk", 30),
    67 => SurahData(arabic ? "ٱلْقَلَمُ" : "Al-Qalam", 52),
    68 => SurahData(arabic ? "ٱلْحَاقَّةُ" : "Al-Haaqqa", 52),
    69 => SurahData(arabic ? "ٱلْمَعَارِجُ" : "Al-Ma'arij", 44),
    70 => SurahData(arabic ? "نُوحٌ" : "Nuh", 28),
    71 => SurahData(arabic ? "ٱلْجِنُّ" : "Al-Jinn", 28),
    72 => SurahData(arabic ? "ٱلْمُزَّمِّلُ" : "Al-Muzzammil", 20),
    73 => SurahData(arabic ? "ٱلْمُدَّثِّرُ" : "Al-Muddaththir", 56),
    74 => SurahData(arabic ? "ٱلْقِيَامَةُ" : "Al-Qiyama", 40),
    75 => SurahData(arabic ? "ٱلْإِنْسَانُ" : "Al-Insan", 31),
    76 => SurahData(arabic ? "ٱلْمُرْسَلَاتُ" : "Al-Mursalat", 50),
    77 => SurahData(arabic ? "ٱلنَّبَأُ" : "An-Naba", 40),
    78 => SurahData(arabic ? "ٱلنَّازِعَاتُ" : "An-Nazi'at", 46),
    79 => SurahData(arabic ? "عَبَسَ" : "Abasa", 42),
    80 => SurahData(arabic ? "ٱلتَّكْوِيرُ" : "At-Takwir", 29),
    81 => SurahData(arabic ? "ٱلْإِنْفِطَارُ" : "Al-Infitar", 19),
    82 => SurahData(arabic ? "ٱلْمُطَفِّفِينَ" : "Al-Mutaffifin", 36),
    83 => SurahData(arabic ? "ٱلْإِنْشِقَاقُ" : "Al-Inshiqaq", 25),
    84 => SurahData(arabic ? "ٱلْبُرُوجُ" : "Al-Buruj", 22),
    85 => SurahData(arabic ? "ٱلطَّارِقُ" : "At-Tariq", 17),
    86 => SurahData(arabic ? "ٱلْأَعْلَىٰ" : "Al-A'la", 19),
    87 => SurahData(arabic ? "ٱلْغَاشِيَةُ" : "Al-Ghashiyah", 26),
    88 => SurahData(arabic ? "ٱلْفَجْرُ" : "Al-Fajr", 30),
    89 => SurahData(arabic ? "ٱلْبَلَدُ" : "Al-Balad", 20),
    90 => SurahData(arabic ? "ٱلشَّمْسُ" : "Ash-Shams", 15),
    91 => SurahData(arabic ? "ٱللَّيْلُ" : "Al-Layl", 21),
    92 => SurahData(arabic ? "ٱلضُّحَىٰ" : "Ad-Duha", 11),
    93 => SurahData(arabic ? "ٱلشَّرْحُ" : "Ash-Sharh", 8),
    94 => SurahData(arabic ? "ٱلتِّينُ" : "At-Tin", 8),
    95 => SurahData(arabic ? "ٱلْعَلَقُ" : "Al-Alaq", 19),
    96 => SurahData(arabic ? "ٱلْقَدْرُ" : "Al-Qadr", 5),
    97 => SurahData(arabic ? "ٱلْبَيِّنَةُ" : "Al-Bayyina", 8),
    98 => SurahData(arabic ? "ٱلزَّلْزَلَةُ" : "Az-Zalzalah", 8),
    99 => SurahData(arabic ? "ٱلْعَادِيَاتُ" : "Al-Adiyat", 11),
    100 => SurahData(arabic ? "ٱلْقَارِعَةُ" : "Al-Qari'ah", 11),
    101 => SurahData(arabic ? "ٱلتَّكَاثُرُ" : "At-Takathur", 8),
    102 => SurahData(arabic ? "ٱلْعَصْرُ" : "Al-Asr", 3),
    103 => SurahData(arabic ? "ٱلْهُمَزَةُ" : "Al-Humazah", 9),
    104 => SurahData(arabic ? "ٱلْفِيلُ" : "Al-Fil", 5),
    105 => SurahData(arabic ? "لِإِيلَٰفِ قُرَيْشٍ" : "Quraysh", 4),
    106 => SurahData(arabic ? "ٱلْمَاعُونَ" : "Al-Ma'un", 7),
    107 => SurahData(arabic ? "ٱلْكَوْثَرُ" : "Al-Kawthar", 3),
    108 => SurahData(arabic ? "ٱلْكَافِرُونَ" : "Al-Kafirun", 6),
    109 => SurahData(arabic ? "ٱلنَّصْرُ" : "An-Nasr", 3),
    110 => SurahData(arabic ? "ٱلْمَسَدُ" : "Al-Masad", 5),
    111 => SurahData(arabic ? "ٱلْإِخْلَاصُ" : "Al-Ikhlas", 4),
    112 => SurahData(arabic ? "ٱلْفَلَقُ" : "Al-Falaq", 5),
    113 => SurahData(arabic ? "ٱلنَّاسُ" : "An-Nas", 6),
    _ => throw "Invalid surah idx: $idx",
  };
}

int surahGlyphCode(int surahIndex) {
  const codes = [
    0xe904 + 0,
    0xe904 + 1,
    0xe904 + 2,
    0xe904 + 3,
    0xe904 + 4,
    0xe904 + 7,
    0xe904 + 8,
    0xe904 + 9,
    0xe904 + 10,
    0xe904 + 11,
    0xe904 + 12,
    0xe904 + 13,
    0xe904 + 14,
    0xe904 + 15,
    0xe904 + 16,
    0xe904 + 17,
    0xe904 + 18,
    0xe904 + 19,
    0xe904 + 20,
    0xe904 + 21,
    0xe904 + 22,
    0xe904 + 23,
    0xe904 + 24,
    0xe904 + 25,
    0xe904 + 26,
    0xe904 + 27,
    0xe904 + 28,
    0xe904 + 29,
    0xe904 + 30,
    0xe904 + 31,
    0xe904 + 32,
    0xe904 + 33,
    0xe904 + 34,
    0xe904 + 42,
    0xe904 + 43,
    0xe904 + 44,
    0xe904 + 45,
    0xe904 + 5,
    0xe904 + 6,
    0xe904 + 35,
    0xe904 + 36,
    0xe904 + 37,
    0xe904 + 38,
    0xe904 + 39,
    0xe904 + 40,
    0xe904 + 41,
    0xe904 + 46,
    0xe902,
    0xe904 + 47,
    0xe904 + 48,
    0xe904 + 49,
    0xe904 + 50,
    0xe904 + 51,
    0xe904 + 52,
    0xe904 + 53,
    0xe904 + 54,
    0xe904 + 55,
    0xe904 + 56,
    0xe900,
    0xe901,
    0xe904 + 61,
    0xe904 + 62,
    0xe904 + 63,
    0xe904 + 64,
    0xe904 + 65,
    0xe904 + 66,
    0xe904 + 67,
    0xe904 + 68,
    0xe904 + 69,
    0xe904 + 70,
    0xe904 + 71,
    0xe904 + 72,
    0xe904 + 73,
    0xe904 + 74,
    0xe904 + 75,
    0xe904 + 76,
    0xe904 + 77,
    0xe904 + 78,
    0xe904 + 57,
    0xe904 + 58,
    0xe904 + 59,
    0xe904 + 60,
    0xe904 + 79,
    0xe904 + 80,
    0xe904 + 81,
    0xe904 + 82,
    0xe904 + 83,
    0xe904 + 84,
    0xe904 + 85,
    0xe904 + 86,
    0xe904 + 87,
    0xe904 + 88,
    0xe904 + 89,
    0xe904 + 90,
    0xe904 + 91,
    0xe904 + 92,
    0xe904 + 93,
    0xe904 + 94,
    0xe904 + 95,
    0xe904 + 96,
    0xe904 + 97,
    0xe904 + 98,
    0xe904 + 99,
    0xe904 + 100,
    0xe904 + 101,
    0xe904 + 102,
    0xe904 + 103,
    0xe904 + 104,
    0xe904 + 105,
    0xe904 + 106,
    0xe904 + 107,
    0xe904 + 108,
    0xe904 + 109,
    0xe904 + 110,
  ];
  return codes[surahIndex];
}

Uint32List getSurahAyahStarts() {
  return _surahAyahOffsets;
}

List<int> _surahsStartsInPara(int paraIdx) {
  return switch (paraIdx) {
    0 => const [0, 1],
    1 => const [],
    2 => const [2],
    3 => const [3],
    4 => const [],
    5 => const [4],
    6 => const [5],
    7 => const [6],
    8 => const [7],
    9 => const [8],
    10 => const [9, 10],
    11 => const [11],
    12 => const [12, 13, 14],
    13 => const [15],
    14 => const [16, 17],
    15 => const [18, 19],
    16 => const [20, 21],
    17 => const [22, 23, 24],
    18 => const [25, 26],
    19 => const [27, 28],
    20 => const [29, 30, 31, 32],
    21 => const [33, 34, 35],
    22 => const [36, 37, 38],
    23 => const [39, 40],
    24 => const [41, 42, 43, 44],
    25 => const [45, 46, 47, 48, 49, 50],
    26 => const [51, 52, 53, 54, 55, 56],
    27 => const [57, 58, 59, 60, 61, 62, 63, 64, 65],
    28 => const [66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76],
    29 => const [/* 77 - 113 */],
    _ => throw "Invalid para idx: $paraIdx",
  };
}

int firstSurahInPara(int paraIdx) {
  if (paraIdx == 29) {
    return 77;
  } else {
    final List<int> surahs = _surahsStartsInPara(paraIdx);
    if (surahs.isNotEmpty) {
      return surahs.first;
    }
    return _surahsStartsInPara(paraIdx - 1).first;
  }
}

List<int> surahAyahOffsetsForPara(int paraIdx) {
  final List<int> surahs =
      paraIdx < 29
          ? _surahsStartsInPara(paraIdx)
          : [for (int s = 77; s < 114; ++s) s];
  return [for (final s in surahs) _surahAyahOffsets[s]];
}

int surahForPage(int page, Mushaf mushaf) {
  int extra = switch (mushaf) {
    Mushaf.Indopak16Line => 1,
    Mushaf.Uthmani15Line => 0,
    Mushaf.Indopak15Line => 1,
  };
  page += extra;

  if (mushaf == Mushaf.Indopak16Line && (page < 1 || page > 549)) {
    throw "Invalid page number: $page";
  } else if (mushaf == Mushaf.Uthmani15Line && (page < 0 || page > 604)) {
    throw "Invalid page number: $page";
  }

  final list = switch (mushaf) {
    Mushaf.Indopak16Line => surah16LinePageOffset,
    Mushaf.Uthmani15Line => surah15LinePageOffset,
    Mushaf.Indopak15Line => surah15LineIndopakPageOffset,
  };

  for (int i = 0; i < 114; ++i) {
    if (page >= list[i]) {
      continue;
    }
    return i - 1;
  }
  return 114 - 1;
}

final Uint32List _surahAyahOffsets = Uint32List.fromList(<int>[
  0,
  7,
  293,
  493,
  669,
  789,
  954,
  1160,
  1235,
  1364,
  1473,
  1596,
  1707,
  1750,
  1802,
  1901,
  2029,
  2140,
  2250,
  2348,
  2483,
  2595,
  2673,
  2791,
  2855,
  2932,
  3159,
  3252,
  3340,
  3409,
  3469,
  3503,
  3533,
  3606,
  3660,
  3705,
  3788,
  3970,
  4058,
  4133,
  4218,
  4272,
  4325,
  4414,
  4473,
  4510,
  4545,
  4583,
  4612,
  4630,
  4675,
  4735,
  4784,
  4846,
  4901,
  4979,
  5075,
  5104,
  5126,
  5150,
  5163,
  5177,
  5188,
  5199,
  5217,
  5229,
  5241,
  5271,
  5323,
  5375,
  5419,
  5447,
  5475,
  5495,
  5551,
  5591,
  5622,
  5672,
  5712,
  5758,
  5800,
  5829,
  5848,
  5884,
  5909,
  5931,
  5948,
  5967,
  5993,
  6023,
  6043,
  6058,
  6079,
  6090,
  6098,
  6106,
  6125,
  6130,
  6138,
  6146,
  6157,
  6168,
  6176,
  6179,
  6188,
  6193,
  6197,
  6204,
  6207,
  6213,
  6216,
  6221,
  6225,
  6230,
]);
