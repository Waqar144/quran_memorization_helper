import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'ayat.dart';
import 'ayat_list_view.dart';
import 'para_bounds.dart';

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
        paraByteBounds[para - 1].start, paraByteBounds[para - 1].end);
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
