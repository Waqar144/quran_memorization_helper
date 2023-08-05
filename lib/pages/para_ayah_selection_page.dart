import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:quran_memorization_helper/widgets/ayat_list_view.dart';
import 'package:quran_memorization_helper/quran_data/para_bounds.dart';
import 'package:quran_memorization_helper/quran_data/ayat.dart';

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
  }

  Future<void> _importParaText(int para) async {
    try {
      final data = await rootBundle.load("assets/quran.txt");
      _ayats = await getParaAyahs(para - 1, data.buffer);
    } catch (e) {
      rethrow;
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
