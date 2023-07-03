import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'ayat.dart';
import 'ayat_list_view.dart';

class _ParaBounds {
  final int start;
  final int end;
  const _ParaBounds(this.start, this.end);
}

// const List<_ParaBounds> _paraBounds = [
//   _ParaBounds(1, 148), // 1
//   _ParaBounds(149, 259), // 2
//   _ParaBounds(260, 384), // 3
//   _ParaBounds(385, 516), // 4
//   _ParaBounds(517, 640), // 5
//   _ParaBounds(641, 751), // 6
//   _ParaBounds(752, 899), // 7
//   _ParaBounds(900, 1041), // 8
//   _ParaBounds(1042, 1200), // 9
//   _ParaBounds(1201, 1328), // 10
//   _ParaBounds(1329, 1478), // 11
//   _ParaBounds(1479, 1648), // 12
//   _ParaBounds(1649, 1803), // 13
//   _ParaBounds(1804, 2029), // 14
//   _ParaBounds(2030, 2214), // 15
//   _ParaBounds(2215, 2483), // 16
//   _ParaBounds(2484, 2673), // 17
//   _ParaBounds(2674, 2875), // 18
//   _ParaBounds(2876, 3218), // 19
//   _ParaBounds(3219, 3384), // 20
//   _ParaBounds(3385, 3563), // 21
//   _ParaBounds(3564, 3726), // 22
//   _ParaBounds(3727, 4089), // 23
//   _ParaBounds(4090, 4264), // 24
//   _ParaBounds(4265, 4510), // 25
//   _ParaBounds(4511, 4705), // 26
//   _ParaBounds(4706, 5104), // 27
//   _ParaBounds(5105, 5241), // 28
//   _ParaBounds(5242, 5672), // 29
//   _ParaBounds(5673, 6236), // 30
// ];

const List<_ParaBounds> _paraByteBounds = [
  _ParaBounds(0, 24080),
  _ParaBounds(24081, 48937),
  _ParaBounds(48938, 73433),
  _ParaBounds(73434, 97802),
  _ParaBounds(97803, 122666),
  _ParaBounds(122667, 147323),
  _ParaBounds(147324, 173147),
  _ParaBounds(173148, 197637),
  _ParaBounds(197638, 222064),
  _ParaBounds(222065, 245871),
  _ParaBounds(245872, 270646),
  _ParaBounds(270647, 295598),
  _ParaBounds(295599, 320083),
  _ParaBounds(320084, 343998),
  _ParaBounds(343999, 369288),
  _ParaBounds(369289, 394503),
  _ParaBounds(394504, 417750),
  _ParaBounds(417751, 443310),
  _ParaBounds(443311, 469035),
  _ParaBounds(469036, 492361),
  _ParaBounds(492362, 517038),
  _ParaBounds(517039, 541513),
  _ParaBounds(541514, 567188),
  _ParaBounds(567189, 590887),
  _ParaBounds(590888, 616139),
  _ParaBounds(616140, 641435),
  _ParaBounds(641436, 666396),
  _ParaBounds(666397, 691925),
  _ParaBounds(691926, 717702),
  _ParaBounds(717703, 740472),
];

class ParaAyahSelectionPage extends StatefulWidget {
  final int _paraNum;

  const ParaAyahSelectionPage(this._paraNum, {super.key});

  @override
  State<StatefulWidget> createState() => _ParaAyahSelectionPageState();
}

class _ParaAyahSelectionPageState extends State<ParaAyahSelectionPage> {
  late final String _para;
  List<Ayat> _ayats = [];

  @override
  void initState() {
    super.initState();

    _para = "Para ${widget._paraNum}";
    _importParaText(widget._paraNum);
  }

  Future<void> _importParaText(int para) async {
    final data = await rootBundle.load("assets/quran.txt");
    var str = utf8.decode(data.buffer.asUint8List());

    str = str.substring(
        _paraByteBounds[para - 1].start, _paraByteBounds[para - 1].end);
    final List<String> lines = str.split('\n');
    _ayats = <Ayat>[for (int i = 0; i < lines.length; ++i) Ayat(lines[i])];
  }

  void _onDone(BuildContext context) {
    List<Ayat> selected = [
      for (final a in _ayats)
        if (a.selected ?? false) a
    ];
    Navigator.pop(context, selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Ayahs From $_para"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => _onDone(context),
          )
        ],
      ),
      body: FutureBuilder(
        future: _importParaText(widget._paraNum),
        builder: (context, snapshot) {
          if (_ayats.isEmpty) return const SizedBox.shrink();
          return AyatListView(
            _ayats,
            selectionMode: true,
            onLongPress: () {},
          );
        },
      ),
    );
  }
}
