import 'dart:typed_data';

import 'package:quran_memorization_helper/models/settings.dart';
import 'fifteen_line_uthmani_layout.dart';
import 'sixteen_line_indopak_layout.dart';
import 'fifteen_line_indopak_layout.dart';

int pageCount(Mushaf m) {
  return switch (m) {
    Mushaf.Indopak16Line => 548,
    Mushaf.Uthmani15Line => 604,
    Mushaf.Indopak15Line => 610,
  };
}

final Uint16List _para16LinePageOffsets = Uint16List.fromList(<int>[
  0, // 1
  19, // 2
  37, // 3
  55, // 4
  73, // 5
  91, // 6
  109, // 7
  127, // 8
  145, // 9
  163, // 10
  181, // 11
  199, // 12
  217, // 13
  235, // 14
  253, // 15
  271, // 16
  289, // 17
  307, // 18
  325, // 19
  343, // 20
  361, // 21
  379, // 22
  397, // 23
  415, // 24
  433, // 25
  451, // 26
  469, // 27
  487, // 28
  507, // 29
  527, // 30
]);

final Uint16List _para15LinePageOffsets = Uint16List.fromList([
  0, // 1
  21, // 2
  41, // 3
  61, // 4
  81, // 5
  101, // 6
  121, // 7
  141, // 8
  161, // 9
  181, // 10
  201, // 11
  221, // 12
  241, // 13
  261, // 14
  281, // 15
  301, // 16
  321, // 17
  341, // 18
  361, // 19
  381, // 20
  401, // 21
  421, // 22
  441, // 23
  461, // 24
  481, // 25
  501, // 26
  521, // 27
  541, // 28
  561, // 29
  581, // 30
]);

final Uint16List _para15LineIndoPakPageOffsets = Uint16List.fromList([
  0, // 1
  21, // 2
  41, // 3
  61, // 4
  81, // 5
  101, // 6
  121, // 7
  141, // 8
  161, // 9
  181, // 10
  201, // 11
  221, // 12
  241, // 13
  261, // 14
  281, // 15
  301, // 16
  321, // 17
  341, // 18
  361, // 19
  381, // 20
  401, // 21
  421, // 22
  441, // 23
  461, // 24
  481, // 25
  501, // 26
  521, // 27
  541, // 28
  561, // 29
  585, // 30
]);

int paraStartPage(int paraIdx, Mushaf mushaf) {
  final list = paraPageOffsetsList(mushaf);
  return list[paraIdx];
}

Uint16List paraPageOffsetsList(Mushaf mushaf) {
  return switch (mushaf) {
    Mushaf.Indopak16Line => _para16LinePageOffsets,
    Mushaf.Uthmani15Line => _para15LinePageOffsets,
    Mushaf.Indopak15Line => _para15LineIndoPakPageOffsets,
  };
}

int surahStartPage(int surahIdx, Mushaf mushaf) {
  final surahList = switch (mushaf) {
    Mushaf.Indopak16Line => surah16LinePageOffset,
    Mushaf.Uthmani15Line => surah15LinePageOffset,
    Mushaf.Indopak15Line => surah15LineIndopakPageOffset,
  };
  return surahList[surahIdx];
}

int pageCountForPara(int paraIdx, Mushaf mushaf) {
  if (paraIdx == 29) {
    return switch (mushaf) {
      Mushaf.Indopak16Line => 22,
      Mushaf.Uthmani15Line => 23,
      Mushaf.Indopak15Line => 25,
    };
  }

  final list = paraPageOffsetsList(mushaf);
  int p1 = list[paraIdx];
  int p2 = list[paraIdx + 1];
  return p2 - p1;
}

int paraForPage(int page, Mushaf mushaf) {
  if (mushaf == Mushaf.Indopak16Line && (page < 0 || page > 548)) {
    throw "Invalid page number: $page";
  } else if (mushaf == Mushaf.Uthmani15Line && (page < 0 || page > 604)) {
    throw "Invalid page number: $page";
  }

  final list = paraPageOffsetsList(mushaf);
  for (int i = 0; i < 30; ++i) {
    if (page >= list[i]) {
      continue;
    }
    return i - 1;
  }
  return 30 - 1;
}

int? firstAyahOfPage(int pageIdx, Mushaf mushaf) {
  final pages = switch (mushaf) {
    Mushaf.Indopak16Line => pages16Indopak,
    Mushaf.Uthmani15Line => pages15Uthmani,
    Mushaf.Indopak15Line => pages15Indopak,
  };
  if (pageIdx < pages.length) {
    final page = pages[pageIdx];
    return page.lines.firstWhere((l) => l.ayahIdx >= 0).ayahIdx;
  }
  return null;
}

final Uint16List surah16LinePageOffset = Uint16List.fromList(<int>[
  0, // 1
  1, // 2
  44, // 3
  68, // 4
  95, // 5
  114, // 6
  135, // 7
  158, // 8
  167, // 9
  186, // 10
  198, // 11
  211, // 12
  223, // 13
  229, // 14
  234, // 15
  239, // 16
  253, // 17
  263, // 18
  274, // 19
  280, // 20
  289, // 21
  298, // 22
  307, // 23
  314, // 24
  323, // 25
  329, // 26
  338, // 27
  346, // 28
  356, // 29
  363, // 30
  369, // 31
  372, // 32
  375, // 33
  384, // 34
  390, // 35
  395, // 36
  400, // 37
  407, // 38
  411, // 39
  419, // 40
  428, // 41
  433, // 42
  439, // 43
  445, // 44
  447, // 45
  451, // 46
  455, // 47
  459, // 48
  462, // 49
  465, // 50
  467, // 51
  470, // 52
  472, // 53
  474, // 54
  477, // 55
  480, // 56
  483, // 57
  487, // 58
  490, // 59
  494, // 60
  496, // 61
  498, // 62
  499, // 63
  501, // 64
  503, // 65
  505, // 66
  507, // 67
  509, // 68
  511, // 69
  513, // 70
  515, // 71
  517, // 72
  519, // 73
  520, // 74
  522, // 75
  523, // 76
  525, // 77
  527, // 78
  528, // 79
  529, // 80
  531, // 81
  531, // 82
  532, // 83
  533, // 84
  534, // 85
  535, // 86
  536, // 87
  536, // 88
  537, // 89
  538, // 90
  539, // 91
  539, // 92
  540, // 93
  540, // 94
  541, // 95
  541, // 96
  542, // 97
  542, // 98
  543, // 99
  543, // 100
  543, // 101
  544, // 102
  544, // 103
  544, // 104
  545, // 105
  545, // 106
  545, // 107
  545, // 108
  546, // 109
  546, // 110
  546, // 111
  546, // 112
  547, // 113
  547, // 114
]);

final Uint16List surah15LinePageOffset = Uint16List.fromList(<int>[
  0,
  1,
  49,
  76,
  105,
  127,
  150,
  176,
  186,
  207,
  220,
  234,
  248,
  254,
  261,
  266,
  281,
  292,
  304,
  311,
  321,
  331,
  341,
  349,
  358,
  366,
  376,
  384,
  395,
  403,
  410,
  414,
  417,
  427,
  433,
  439,
  445,
  452,
  457,
  466,
  476,
  482,
  488,
  495,
  498,
  501,
  506,
  510,
  514,
  517,
  519,
  522,
  525,
  527,
  530,
  533,
  536,
  541,
  544,
  548,
  550,
  552,
  553,
  555,
  557,
  559,
  561,
  563,
  565,
  567,
  569,
  571,
  573,
  574,
  576,
  577,
  579,
  581,
  582,
  584,
  585,
  586,
  586,
  588,
  589,
  590,
  590,
  591,
  592,
  592,
  593,
  594,
  594,
  595,
  595,
  596,
  596,
  597,
  597,
  598,
  598,
  599,
  599,
  600,
  600,
  601,
  601,
  601,
  602,
  602,
  602,
  603,
  603,
  603,
]);

final Uint16List surah15LineIndopakPageOffset = Uint16List.fromList(<int>[
  0, // 1
  1, // 2
  49, // 3
  76, // 4
  105, // 5
  127, // 6
  150, // 7
  176, // 8
  186, // 9
  207, // 10
  220, // 11
  234, // 12
  248, // 13
  254, // 14
  260, // 15
  266, // 16
  281, // 17
  292, // 18
  304, // 19
  311, // 20
  321, // 21
  330, // 22
  341, // 23
  349, // 24
  358, // 25
  365, // 26
  375, // 27
  384, // 28
  395, // 29
  403, // 30
  410, // 31
  414, // 32
  417, // 33
  427, // 34
  433, // 35
  439, // 36
  444, // 37
  451, // 38
  457, // 39
  466, // 40
  476, // 41
  482, // 42
  488, // 43
  494, // 44
  497, // 45
  501, // 46
  505, // 47
  510, // 48
  514, // 49
  517, // 50
  519, // 51
  522, // 52
  525, // 53
  527, // 54
  530, // 55
  533, // 56
  536, // 57
  541, // 58
  544, // 59
  548, // 60
  550, // 61
  552, // 62
  553, // 63
  555, // 64
  557, // 65
  559, // 66
  561, // 67
  563, // 68
  566, // 69
  568, // 70
  570, // 71
  572, // 72
  575, // 73
  577, // 74
  579, // 75
  581, // 76
  583, // 77
  585, // 78
  586, // 79
  588, // 80
  589, // 81
  590, // 82
  591, // 83
  593, // 84
  594, // 85
  595, // 86
  596, // 87
  597, // 88
  599, // 89
  599, // 90
  600, // 91
  601, // 92
  601, // 93
  602, // 94
  602, // 95
  603, // 96
  603, // 97
  604, // 98
  604, // 99
  605, // 100
  605, // 101
  606, // 102
  606, // 103
  606, // 104
  607, // 105
  607, // 106
  607, // 107
  607, // 108
  608, // 109
  608, // 110
  608, // 111
  608, // 112
  609, // 113
  609, // 114
]);
