import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'page_constants.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:quran_memorization_helper/quran_data/ayat.dart';
import 'package:quran_memorization_helper/models/ayat.dart';
import 'package:quran_memorization_helper/utils/utils.dart';
import 'package:quran_memorization_helper/widgets/mutashabiha_ayat_list_item.dart';

class ParaMutashabihasArgs {
  final ParaAyatModel model;
  final int para;
  const ParaMutashabihasArgs(this.model, this.para);
}

/// The page where you select the para for which the mutashabihas will be displayed
class MutashabihasPage extends StatelessWidget {
  final ParaAyatModel _model;
  const MutashabihasPage(this._model, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mutashabihas By Para"),
      ),
      body: ListView.separated(
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemCount: 30,
        itemBuilder: (context, index) {
          return ListTile(
            visualDensity: VisualDensity.compact,
            title: Text("Para ${index + 1}"),
            onTap: () {
              Navigator.of(context).pushNamed(paraMutashabihasPage,
                  arguments: ParaMutashabihasArgs(_model, index));
            },
          );
        },
      ),
    );
  }
}

/// This is the page that shows the mutashabihas list
class ParaMutashabihas extends StatelessWidget {
  final int _para;
  final ParaAyatModel _model;
  final List<Mutashabiha> _mutashabihas = [];
  final ValueNotifier<bool> _selectionMode = ValueNotifier(false);
  ParaMutashabihas(ParaMutashabihasArgs args, {super.key})
      : _para = args.para,
        _model = args.model;

  /// Import the mutashabihas from assets
  Future<List<Mutashabiha>> _importParaMutashabihas() async {
    final mutashabihasJsonBytes =
        await rootBundle.load("assets/mutashabiha_data.json");
    final mutashabihasJson =
        utf8.decode(mutashabihasJsonBytes.buffer.asUint8List());
    final map = jsonDecode(mutashabihasJson) as Map<String, dynamic>;
    int paraNum = _para + 1;
    final list = map[paraNum.toString()] as List<dynamic>;

    _mutashabihas.clear();
    final ByteData data = await rootBundle.load("assets/quran.txt");
    for (final m in list) {
      if (m == null) continue;
      try {
        int ctx = (m["ctx"] as int?) ?? 0;
        MutashabihaAyat src = ayatFromJsonObj(m["src"], data.buffer, ctx);
        List<MutashabihaAyat> matches = [];
        for (final match in m["muts"]) {
          matches.add(ayatFromJsonObj(match, data.buffer, ctx));
        }
        _mutashabihas.add(Mutashabiha(src, matches));
      } catch (e) {
        rethrow;
      }
    }
    return _mutashabihas;
  }

  void _clearSelection() {
    for (final m in _mutashabihas) {
      m.src.selected = false;
    }
  }

  void _onEnterSelectionMode() {
    _clearSelection();
    _selectionMode.value = !_selectionMode.value;
  }

  void _onAddToDB(BuildContext context) async {
    final selection = [
      for (final m in _mutashabihas)
        if (m.src.selected ?? false) m
    ];

    _clearSelection();
    _selectionMode.value = false;

    if (selection.isEmpty) return;

    _model.setParaMutashabihas(_para + 1, selection);
    String path = await _model.saveToDisk();
    if (context.mounted) showSnackBarMessage(context, "Saved to file $path");
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectionMode.value) {
          _selectionMode.value = false;
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Mutashabihas for Para ${_para + 1}"),
          actions: [
            ValueListenableBuilder(
              valueListenable: _selectionMode,
              builder: (ctx, value, _) {
                if (value == false) {
                  return IconButton(
                    icon: const Icon(Icons.add_box),
                    onPressed: _onEnterSelectionMode,
                    tooltip: "Add mutashabihas to list",
                  );
                } else {
                  return IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () => _onAddToDB(context),
                    tooltip: "Add mutashabihas to list",
                  );
                }
              },
            )
          ],
        ),
        body: FutureBuilder(
          future: _importParaMutashabihas(),
          builder: (context, snapshot) {
            final data = snapshot.data;
            // No data => nothing to show
            if (data == null || data.isEmpty) return const SizedBox.shrink();
            // Build the mutashabiha list
            return ValueListenableBuilder(
              valueListenable: _selectionMode,
              builder: (context, value, _) {
                return ListView.separated(
                  separatorBuilder: (ctx, index) => const Divider(height: 1),
                  itemCount: data.length,
                  itemBuilder: (ctx, index) {
                    return MutashabihaAyatListItem(
                      mutashabiha: data[index],
                      selectionMode: _selectionMode.value,
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
