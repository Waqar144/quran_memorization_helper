import 'dart:typed_data';

class ParaBounds {
  final int start;
  final int end;
  const ParaBounds(this.start, this.end);
}

const String ayahSeparator = " ۞ ";

int paraForAyah(int absoluteAyah) {
  for (int i = 0; i < _paraAyahOffset.length; ++i) {
    if (absoluteAyah > _paraAyahOffset[i]) continue;
    return i - 1;
  }
  // last para
  return 29;
}

const List<int> paraByteOffsets = [
  0,
  46001,
  93470,
  140239,
  186771,
  234056,
  281015,
  330152,
  376762,
  423322,
  468690,
  515826,
  563289,
  609936,
  655590,
  703706,
  751712,
  796001,
  844747,
  893981,
  938399,
  985397,
  1031796,
  1080913,
  1125959,
  1174160,
  1222376,
  1270319,
  1318999,
  1368340,
];

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

const List<int> paraAyahCount = [
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
];

final Uint32List _paraAyahOffset = Uint32List.fromList([
  0,
  148,
  259,
  384,
  516,
  640,
  751,
  899,
  1041,
  1200,
  1328,
  1478,
  1648,
  1803,
  2029,
  2214,
  2483,
  2673,
  2875,
  3218,
  3384,
  3563,
  3726,
  4089,
  4264,
  4510,
  4705,
  5104,
  5241,
  5672,
]);
