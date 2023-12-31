import 'dart:typed_data';

final Uint16List para16LinePageOffsets = Uint16List.fromList([
  1, // 1
  20, // 2
  38, // 3
  56, // 4
  74, // 5
  92, // 6
  110, // 7
  128, // 8
  146, // 9
  164, // 10
  182, // 11
  200, // 12
  218, // 13
  236, // 14
  254, // 15
  272, // 16
  290, // 17
  308, // 18
  326, // 19
  344, // 20
  362, // 21
  380, // 22
  398, // 23
  416, // 24
  434, // 25
  452, // 26
  470, // 27
  488, // 28
  508, // 29
  528, // 30
]);

int pageCountForPara(int paraIdx) {
  if (paraIdx == 29) {
    return 22;
  }
  int p1 = para16LinePageOffsets[paraIdx];
  int p2 = para16LinePageOffsets[paraIdx + 1];
  return p2 - p1;
}

int paraForPage(int page) {
  if (page < 0 || page > 548) {
    throw "Invalid page number: $page";
  }

  for (int i = 0; i < 30; ++i) {
    if (page >= para16LinePageOffsets[i]) {
      continue;
    }
    return i - 1;
  }
  return 30 - 1;
}

final Uint16List surah16LinePageOffset = Uint16List.fromList([
  2,
  3,
  46,
  70,
  97,
  116,
  137,
  160,
  169,
  188,
  200,
  213,
  225,
  231,
  236,
  241,
  255,
  265,
  276,
  282,
  291,
  300,
  309,
  316,
  325,
  331,
  340,
  348,
  358,
  365,
  371,
  374,
  377,
  386,
  392,
  397,
  402,
  409,
  413,
  421,
  430,
  435,
  441,
  447,
  449,
  453,
  457,
  461,
  464,
  467,
  469,
  472,
  474,
  476,
  479,
  482,
  485,
  489,
  492,
  496,
  498,
  500,
  501,
  503,
  505,
  507,
  509,
  511,
  513,
  515,
  517,
  519,
  521,
  522,
  524,
  525,
  527,
  529,
  530,
  531,
  533,
  533,
  534,
  535,
  536,
  537,
  538,
  538,
  539,
  540,
  541,
  541,
  542,
  542,
  543,
  543,
  544,
  544,
  545,
  545,
  545,
  546,
  546,
  546,
  547,
  547,
  547,
  547,
  548,
  548,
  548,
  548,
  549,
  549,
]);
