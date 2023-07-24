int toSurahAyahOffset(int surahIdx, int absoluteAyah) {
  if (surahIdx > _surahAyahOffsets.length) {
    throw "Invalid surah $surahIdx";
  }
  return absoluteAyah - _surahAyahOffsets[surahIdx];
}

String surahNameForIdx(idx) {
  switch (idx) {
    case 0:
      return "Al-Fatihah";
    case 1:
      return "Al-Baqarah";
    case 2:
      return "Ali 'Imran";
    case 3:
      return "An-Nisa";
    case 4:
      return "Al-Ma'idah";
    case 5:
      return "Al-An'am";
    case 6:
      return "Al-A'raf";
    case 7:
      return "Al-Anfal";
    case 8:
      return "At-Tawbah";
    case 9:
      return "Yunus";
    case 10:
      return "Hud";
    case 11:
      return "Yusuf";
    case 12:
      return "Ar-Ra'd";
    case 13:
      return "Ibrahim";
    case 14:
      return "Al-Hijr";
    case 15:
      return "An-Nahl";
    case 16:
      return "Al-Isra";
    case 17:
      return "Al-Kahf";
    case 18:
      return "Maryam";
    case 19:
      return "Taha";
    case 20:
      return "Al-Anbya";
    case 21:
      return "Al-Hajj";
    case 22:
      return "Al-Mu'minun";
    case 23:
      return "An-Nur";
    case 24:
      return "Al-Furqan";
    case 25:
      return "Ash-Shu'ara";
    case 26:
      return "An-Naml";
    case 27:
      return "Al-Qasas";
    case 28:
      return "Al-'Ankabut";
    case 29:
      return "Ar-Rum";
    case 30:
      return "Luqman";
    case 31:
      return "As-Sajdah";
    case 32:
      return "Al-Ahzab";
    case 33:
      return "Saba";
    case 34:
      return "Fatir";
    case 35:
      return "Ya-Sin";
    case 36:
      return "As-Saffat";
    case 37:
      return "Sad";
    case 38:
      return "Az-Zumar";
    case 39:
      return "Ghafir";
    case 40:
      return "Fussilat";
    case 41:
      return "Ash-Shuraa";
    case 42:
      return "Az-Zukhruf";
    case 43:
      return "Ad-Dukhan";
    case 44:
      return "Al-Jathiyah";
    case 45:
      return "Al-Ahqaf";
    case 46:
      return "Muhammad";
    case 47:
      return "Al-Fath";
    case 48:
      return "Al-Hujurat";
    case 49:
      return "Qaf";
    case 50:
      return "Adh-Dhariyat";
    case 51:
      return "At-Tur";
    case 52:
      return "An-Najm";
    case 53:
      return "Al-Qamar";
    case 54:
      return "Ar-Rahman";
    case 55:
      return "Al-Waqi'ah";
    case 56:
      return "Al-Hadid";
    case 57:
      return "Al-Mujadila";
    case 58:
      return "Al-Hashr";
    case 59:
      return "Al-Mumtahanah";
    case 60:
      return "As-Saf";
    case 61:
      return "Al-Jumu'ah";
    case 62:
      return "Al-Munafiqun";
    case 63:
      return "At-Taghabun";
    case 64:
      return "At-Talaq";
    case 65:
      return "At-Tahrim";
    case 66:
      return "Al-Mulk";
    case 67:
      return "Al-Qalam";
    case 68:
      return "Al-Haqqah";
    case 69:
      return "Al-Ma'arij";
    case 70:
      return "Nuh";
    case 71:
      return "Al-Jinn";
    case 72:
      return "Al-Muzzammil";
    case 73:
      return "Al-Muddaththir";
    case 74:
      return "Al-Qiyamah";
    case 75:
      return "Al-Insan";
    case 76:
      return "Al-Mursalat";
    case 77:
      return "An-Naba";
    case 78:
      return "An-Nazi'at";
    case 79:
      return "'Abasa";
    case 80:
      return "At-Takwir";
    case 81:
      return "Al-Infitar";
    case 82:
      return "Al-Mutaffifin";
    case 83:
      return "Al-Inshiqaq";
    case 84:
      return "Al-Buruj";
    case 85:
      return "At-Tariq";
    case 86:
      return "Al-A'la";
    case 87:
      return "Al-Ghashiyah";
    case 88:
      return "Al-Fajr";
    case 89:
      return "Al-Balad";
    case 90:
      return "Ash-Shams";
    case 91:
      return "Al-Layl";
    case 92:
      return "Ad-Duhaa";
    case 93:
      return "Ash-Sharh";
    case 94:
      return "At-Tin";
    case 95:
      return "Al-'Alaq";
    case 96:
      return "Al-Qadr";
    case 97:
      return "Al-Bayyinah";
    case 98:
      return "Az-Zalzalah";
    case 99:
      return "Al-'Adiyat";
    case 100:
      return "Al-Qari'ah";
    case 101:
      return "At-Takathur";
    case 102:
      return "Al-'Asr";
    case 103:
      return "Al-Humazah";
    case 104:
      return "Al-Fil";
    case 105:
      return "Quraysh";
    case 106:
      return "Al-Ma'un";
    case 107:
      return "Al-Kawthar";
    case 108:
      return "Al-Kafirun";
    case 109:
      return "An-Nasr";
    case 110:
      return "Al-Masad";
    case 111:
      return "Al-Ikhlas";
    case 112:
      return "Al-Falaq";
    case 113:
      return "An-Nas";
  }
  throw "Invalid surah idx: $idx";
}

const List<int> _surahAyahOffsets = [
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
];
