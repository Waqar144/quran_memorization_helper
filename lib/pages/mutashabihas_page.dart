import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/models/settings.dart';
import 'page_constants.dart';
import 'package:quran_memorization_helper/quran_data/ayat.dart';
import 'package:quran_memorization_helper/widgets/mutashabiha_ayat_list_item.dart';
import 'package:quran_memorization_helper/utils/utils.dart';

/// The page where you select the para for which the mutashabihas will be displayed
class MutashabihasPage extends StatelessWidget {
  const MutashabihasPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isIndoPk = isIndoPak(Settings.instance.mushaf);
    return Scaffold(
      appBar: AppBar(
        title:
            isIndoPk
                ? const Text("Mutashabihas By Para")
                : const Text("Mutashabihas By Juz"),
      ),
      body: ListView.separated(
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemCount: 30,
        itemBuilder: (context, index) {
          return ListTile(
            visualDensity: VisualDensity.compact,
            title: Text("${paraText()} ${index + 1}"),
            onTap: () {
              Navigator.of(
                context,
              ).pushNamed(paraMutashabihasPage, arguments: index);
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
  final List<Mutashabiha> _mutashabihas = [];
  ParaMutashabihas(this._para, {super.key});

  /// Import the mutashabihas from assets
  Future<List<Mutashabiha>> _importParaMutashabihas() async {
    _mutashabihas.clear();
    _mutashabihas.addAll(await importParaMutashabihas(_para));
    return _mutashabihas;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mutashabihas for ${paraText()} ${_para + 1}"),
      ),
      body: FutureBuilder(
        future: _importParaMutashabihas(),
        builder: (context, snapshot) {
          final data = snapshot.data;
          // No data => nothing to show
          if (data == null || data.isEmpty) return const SizedBox.shrink();
          // Build the mutashabiha list
          return ListView.separated(
            separatorBuilder: (ctx, index) => const Divider(height: 1),
            itemCount: data.length,
            itemBuilder: (ctx, index) {
              return MutashabihaAyatListItem(
                key: ObjectKey(index),
                mutashabiha: data[index],
                selectionMode: false,
              );
            },
          );
        },
      ),
    );
  }
}
