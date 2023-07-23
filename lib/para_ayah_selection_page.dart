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
  final List<Ayat> _ayats = [];

  @override
  void initState() {
    super.initState();

    _para = "Para ${widget._paraNum}";
  }

  Future<void> _importParaText(int para) async {
    final data = await rootBundle.load("assets/quran.txt");

    const int newLine = 10;
    final int offset = paraByteOffsets[para - 1];
    final int? len = para == 30 ? null : paraByteOffsets[para];
    final buffer = data.buffer.asUint8List(offset, len);
    int s = 0;
    int n = buffer.indexOf(newLine);

    _ayats.clear();
    while (n != -1) {
      final text = utf8.decode(buffer.sublist(s, n));
      _ayats.add(Ayat(text));

      s = n + 1;
      n = buffer.indexOf(newLine, s);
    }
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
