import 'dart:typed_data';

final Uint16List para16LinePageOffsets = Uint16List.fromList(<int>[
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

final Uint16List surah16LinePageOffset = Uint16List.fromList(<int>[
  1,
  2,
  45,
  69,
  96,
  115,
  136,
  159,
  168,
  187,
  199,
  212,
  224,
  230,
  235,
  240,
  254,
  264,
  275,
  281,
  290,
  299,
  308,
  315,
  324,
  330,
  339,
  347,
  357,
  364,
  370,
  373,
  376,
  385,
  391,
  396,
  401,
  408,
  412,
  420,
  429,
  434,
  440,
  446,
  448,
  452,
  456,
  460,
  463,
  466,
  468,
  471,
  473,
  475,
  478,
  481,
  484,
  488,
  491,
  495,
  497,
  499,
  500,
  502,
  504,
  506,
  508,
  510,
  512,
  514,
  516,
  518,
  520,
  521,
  523,
  524,
  526,
  528,
  529,
  530,
  532,
  532,
  533,
  534,
  535,
  536,
  537,
  537,
  538,
  539,
  540,
  540,
  541,
  541,
  542,
  542,
  543,
  543,
  544,
  544,
  544,
  545,
  545,
  545,
  546,
  546,
  546,
  546,
  547,
  547,
  547,
  547,
  548,
  548,
]);
