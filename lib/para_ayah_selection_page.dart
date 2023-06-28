import 'dart:io';
import 'package:flutter/material.dart';

import 'ayat.dart';
import 'ayat_list_view.dart';

class _ParaBounds {
  final int start;
  final int end;
  const _ParaBounds(this.start, this.end);
}

const List<_ParaBounds> _paraBounds = [
  _ParaBounds(1, 148), // 1
  _ParaBounds(149, 259), // 2
  _ParaBounds(260, 384), // 3
  _ParaBounds(385, 516), // 4
  _ParaBounds(517, 640), // 5
  _ParaBounds(641, 751), // 6
  _ParaBounds(752, 899), // 7
  _ParaBounds(900, 1041), // 8
  _ParaBounds(1042, 1200), // 9
  _ParaBounds(1201, 1328), // 10
  _ParaBounds(1329, 1478), // 11
  _ParaBounds(1479, 1648), // 12
  _ParaBounds(1649, 1803), // 13
  _ParaBounds(1804, 2029), // 14
  _ParaBounds(2030, 2214), // 15
  _ParaBounds(2215, 2483), // 16
  _ParaBounds(2484, 2673), // 17
  _ParaBounds(2674, 2875), // 18
  _ParaBounds(2876, 3218), // 19
  _ParaBounds(3219, 3384), // 20
  _ParaBounds(3385, 3563), // 21
  _ParaBounds(3564, 3726), // 22
  _ParaBounds(3727, 4089), // 23
  _ParaBounds(4090, 4264), // 24
  _ParaBounds(4265, 4510), // 25
  _ParaBounds(4511, 4705), // 26
  _ParaBounds(4706, 5104), // 27
  _ParaBounds(5105, 5241), // 28
  _ParaBounds(5242, 5672), // 29
  _ParaBounds(5673, 6236), // 30
];

class ParaAyahSelectionPage extends StatefulWidget {
  final int _paraNum;

  const ParaAyahSelectionPage(this._paraNum, {super.key});

  @override
  State<StatefulWidget> createState() => _ParaAyahSelectionPageState();
}

class _ParaAyahSelectionPageState extends State<ParaAyahSelectionPage> {
  late final String _para;
  final ValueNotifier<bool> _ayahsLoaded = ValueNotifier(false);
  late final List<Ayat> _ayats;

  @override
  void initState() {
    super.initState();

    _para = "Para ${widget._paraNum}";
    _importParaText(widget._paraNum);
  }

  void _importParaText(int para) async {
    final f = File("assets/quran.txt");
    List<String> lines = await f.readAsLines();
    int start = _paraBounds[para - 1].start - 1;
    int end = _paraBounds[para - 1].end;
    _ayats = <Ayat>[for (int i = start; i < end; ++i) Ayat(lines[i])];
    _ayahsLoaded.value = true;
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
      body: ValueListenableBuilder(
        valueListenable: _ayahsLoaded,
        builder: (context, value, _) {
          if (value == false) return const SizedBox.shrink();
          return ListView.separated(
            separatorBuilder: (BuildContext context, int index) =>
                const Divider(
                    indent: 8, endIndent: 8, color: Colors.grey, height: 2),
            itemCount: _ayats.length,
            itemBuilder: (context, index) {
              final ayat = _ayats.elementAt(index);
              final text = ayat.text;
              return AyatListItem(
                key: ObjectKey(ayat),
                model: _ayats,
                text: text,
                idx: index,
                onLongPress: () {},
                selectionMode: true,
              );
            },
          );
        },
      ),
    );
  }
}
