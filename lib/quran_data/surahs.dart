import 'dart:typed_data';

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

String surahNameForIdx(idx) {
  return surahDataForIdx(idx, arabic: false).name;
}

SurahData surahDataForIdx(idx, {bool arabic = false}) {
  return switch (idx) {
    0 => SurahData(arabic ? "الفاتحة" : "Al-Fatihah", 7),
    1 => SurahData(arabic ? "البقرة" : "Al-Baqarah", 286),
    2 => SurahData(arabic ? "آل عمران" : "Ali 'Imran", 200),
    3 => SurahData(arabic ? "النساء" : "An-Nisa", 176),
    4 => SurahData(arabic ? "المائدة" : "Al-Ma'idah", 120),
    5 => SurahData(arabic ? "الأنعام" : "Al-An'am", 165),
    6 => SurahData(arabic ? "الأعراف" : "Al-A'raf", 206),
    7 => SurahData(arabic ? "الأنفال" : "Al-Anfal", 75),
    8 => SurahData(arabic ? "التوبة" : "At-Tawbah", 129),
    9 => SurahData(arabic ? "يونس" : "Yunus", 109),
    10 => SurahData(arabic ? "هود" : "Hud", 123),
    11 => SurahData(arabic ? "يوسف" : "Yusuf", 111),
    12 => SurahData(arabic ? "الرعد" : "Ar-Ra'd", 43),
    13 => SurahData(arabic ? "ابراهيم" : "Ibrahim", 52),
    14 => SurahData(arabic ? "الحجر" : "Al-Hijr", 99),
    15 => SurahData(arabic ? "النحل" : "An-Nahl", 128),
    16 => SurahData(arabic ? "الإسراء" : "Al-Isra", 111),
    17 => SurahData(arabic ? "الكهف" : "Al-Kahf", 110),
    18 => SurahData(arabic ? "مريم" : "Maryam", 98),
    19 => SurahData(arabic ? "طه" : "Taha", 135),
    20 => SurahData(arabic ? "الأنبياء" : "Al-Anbya", 112),
    21 => SurahData(arabic ? "الحج" : "Al-Hajj", 78),
    22 => SurahData(arabic ? "المؤمنون" : "Al-Mu'minun", 118),
    23 => SurahData(arabic ? "النور" : "An-Nur", 64),
    24 => SurahData(arabic ? "الفرقان" : "Al-Furqan", 77),
    25 => SurahData(arabic ? "الشعراء" : "Ash-Shu'ara", 227),
    26 => SurahData(arabic ? "النمل" : "An-Naml", 93),
    27 => SurahData(arabic ? "القصص" : "Al-Qasas", 88),
    28 => SurahData(arabic ? "العنكبوت" : "Al-'Ankabut", 69),
    29 => SurahData(arabic ? "الروم" : "Ar-Rum", 60),
    30 => SurahData(arabic ? "لقمان" : "Luqman", 34),
    31 => SurahData(arabic ? "السجدة" : "As-Sajdah", 30),
    32 => SurahData(arabic ? "الأحزاب" : "Al-Ahzab", 73),
    33 => SurahData(arabic ? "سبإ" : "Saba", 54),
    34 => SurahData(arabic ? "فاطر" : "Fatir", 45),
    35 => SurahData(arabic ? "يس" : "Ya-Sin", 83),
    36 => SurahData(arabic ? "الصافات" : "As-Saffat", 182),
    37 => SurahData(arabic ? "ص" : "Sad", 88),
    38 => SurahData(arabic ? "الزمر" : "Az-Zumar", 75),
    39 => SurahData(arabic ? "غافر" : "Ghafir", 85),
    40 => SurahData(arabic ? "فصلت" : "Fussilat", 54),
    41 => SurahData(arabic ? "الشورى" : "Ash-Shuraa", 53),
    42 => SurahData(arabic ? "الزخرف" : "Az-Zukhruf", 89),
    43 => SurahData(arabic ? "الدخان" : "Ad-Dukhan", 59),
    44 => SurahData(arabic ? "الجاثية" : "Al-Jathiyah", 37),
    45 => SurahData(arabic ? "الأحقاف" : "Al-Ahqaf", 35),
    46 => SurahData(arabic ? "محمد" : "Muhammad", 38),
    47 => SurahData(arabic ? "الفتح" : "Al-Fath", 29),
    48 => SurahData(arabic ? "الحجرات" : "Al-Hujurat", 18),
    49 => SurahData(arabic ? "ق" : "Qaf", 45),
    50 => SurahData(arabic ? "الذاريات" : "Adh-Dhariyat", 60),
    51 => SurahData(arabic ? "الطور" : "At-Tur", 49),
    52 => SurahData(arabic ? "النجم" : "An-Najm", 62),
    53 => SurahData(arabic ? "القمر" : "Al-Qamar", 55),
    54 => SurahData(arabic ? "الرحمن" : "Ar-Rahman", 78),
    55 => SurahData(arabic ? "الواقعة" : "Al-Waqi'ah", 96),
    56 => SurahData(arabic ? "الحديد" : "Al-Hadid", 29),
    57 => SurahData(arabic ? "المجادلة" : "Al-Mujadila", 22),
    58 => SurahData(arabic ? "الحشر" : "Al-Hashr", 24),
    59 => SurahData(arabic ? "الممتحنة" : "Al-Mumtahanah", 13),
    60 => SurahData(arabic ? "الصف" : "As-Saf", 14),
    61 => SurahData(arabic ? "الجمعة" : "Al-Jumu'ah", 11),
    62 => SurahData(arabic ? "المنافقون" : "Al-Munafiqun", 11),
    63 => SurahData(arabic ? "التغابن" : "At-Taghabun", 18),
    64 => SurahData(arabic ? "الطلاق" : "At-Talaq", 12),
    65 => SurahData(arabic ? "التحريم" : "At-Tahrim", 12),
    66 => SurahData(arabic ? "الملك" : "Al-Mulk", 30),
    67 => SurahData(arabic ? "القلم" : "Al-Qalam", 52),
    68 => SurahData(arabic ? "الحاقة" : "Al-Haqqah", 52),
    69 => SurahData(arabic ? "المعارج" : "Al-Ma'arij", 44),
    70 => SurahData(arabic ? "نوح" : "Nuh", 28),
    71 => SurahData(arabic ? "الجن" : "Al-Jinn", 28),
    72 => SurahData(arabic ? "المزمل" : "Al-Muzzammil", 20),
    73 => SurahData(arabic ? "المدثر" : "Al-Muddaththir", 56),
    74 => SurahData(arabic ? "القيامة" : "Al-Qiyamah", 40),
    75 => SurahData(arabic ? "الانسان" : "Al-Insan", 31),
    76 => SurahData(arabic ? "المرسلات" : "Al-Mursalat", 50),
    77 => SurahData(arabic ? "النبإ" : "An-Naba", 40),
    78 => SurahData(arabic ? "النازعات" : "An-Nazi'at", 46),
    79 => SurahData(arabic ? "عبس" : "'Abasa", 42),
    80 => SurahData(arabic ? "التكوير" : "At-Takwir", 29),
    81 => SurahData(arabic ? "الإنفطار" : "Al-Infitar", 19),
    82 => SurahData(arabic ? "المطففين" : "Al-Mutaffifin", 36),
    83 => SurahData(arabic ? "الإنشقاق" : "Al-Inshiqaq", 25),
    84 => SurahData(arabic ? "البروج" : "Al-Buruj", 22),
    85 => SurahData(arabic ? "الطارق" : "At-Tariq", 17),
    86 => SurahData(arabic ? "الأعلى" : "Al-A'la", 19),
    87 => SurahData(arabic ? "الغاشية" : "Al-Ghashiyah", 26),
    88 => SurahData(arabic ? "الفجر" : "Al-Fajr", 30),
    89 => SurahData(arabic ? "البلد" : "Al-Balad", 20),
    90 => SurahData(arabic ? "الشمس" : "Ash-Shams", 15),
    91 => SurahData(arabic ? "الليل" : "Al-Layl", 21),
    92 => SurahData(arabic ? "الضحى" : "Ad-Duhaa", 11),
    93 => SurahData(arabic ? "الشرح" : "Ash-Sharh", 8),
    94 => SurahData(arabic ? "التين" : "At-Tin", 8),
    95 => SurahData(arabic ? "العلق" : "Al-'Alaq", 19),
    96 => SurahData(arabic ? "القدر" : "Al-Qadr", 5),
    97 => SurahData(arabic ? "البينة" : "Al-Bayyinah", 8),
    98 => SurahData(arabic ? "الزلزلة" : "Az-Zalzalah", 8),
    99 => SurahData(arabic ? "العاديات" : "Al-'Adiyat", 11),
    100 => SurahData(arabic ? "القارعة" : "Al-Qari'ah", 11),
    101 => SurahData(arabic ? "التكاثر" : "At-Takathur", 8),
    102 => SurahData(arabic ? "العصر" : "Al-'Asr", 3),
    103 => SurahData(arabic ? "الهمزة" : "Al-Humazah", 9),
    104 => SurahData(arabic ? "الفيل" : "Al-Fil", 5),
    105 => SurahData(arabic ? "قريش" : "Quraysh", 4),
    106 => SurahData(arabic ? "الماعون" : "Al-Ma'un", 7),
    107 => SurahData(arabic ? "الكوثر" : "Al-Kawthar", 3),
    108 => SurahData(arabic ? "الكافرون" : "Al-Kafirun", 6),
    109 => SurahData(arabic ? "النصر" : "An-Nasr", 3),
    110 => SurahData(arabic ? "المسد" : "Al-Masad", 5),
    111 => SurahData(arabic ? "الإخلاص" : "Al-Ikhlas", 4),
    112 => SurahData(arabic ? "الفلق" : "Al-Falaq", 5),
    113 => SurahData(arabic ? "الناس" : "An-Nas", 6),
    _ => throw "Invalid surah idx: $idx"
  };
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
    _ => throw "Invalid para idx: $paraIdx"
  };
}

int firstSurahInPara(int paraIdx) {
  if (paraIdx == 29) {
    return 77;
  } else {
    final surahs = _surahsStartsInPara(paraIdx);
    if (surahs.isNotEmpty) {
      return surahs.first;
    }
    return _surahsStartsInPara(paraIdx - 1).first;
  }
}

List<int> surahAyahOffsetsForPara(int paraIdx) {
  final List<int> surahs = paraIdx < 29
      ? _surahsStartsInPara(paraIdx)
      : [for (int s = 77; s < 114; ++s) s];
  return [for (final s in surahs) _surahAyahOffsets[s]];
}

int surahForPage(int page) {
  if (page < 0 || page > 548) {
    throw "Invalid page number: $page";
  }
  for (int i = 0; i < 114; ++i) {
    if (page >= _surahAyahOffsets[i]) {
      continue;
    }
    return i - 1;
  }
  return 114 - 1;
}

/// returns true if the surah headress (bismillah + surah name)
/// should occupy two lines
/// NOTE: This function should only be used for last para
bool surahHas2LineHeadress(int surah) {
  return [77, 78, 79, 103, 109, 110, 112, 113].contains(surah);
}

final Uint32List _surahAyahOffsets = Uint32List.fromList([
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
  6230
]);
