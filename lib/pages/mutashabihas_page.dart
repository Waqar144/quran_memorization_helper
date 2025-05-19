import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/models/settings.dart';
import 'page_constants.dart';
import 'package:quran_memorization_helper/quran_data/ayat.dart';
import 'package:quran_memorization_helper/widgets/mutashabiha_ayat_list_item.dart';
import 'package:quran_memorization_helper/utils/utils.dart';

/// The page where you select the para for which the mutashabihat will be displayed
class MutashabihatPage extends StatelessWidget {
  const MutashabihatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isIndoPk = isIndoPak(Settings.instance.mushaf);
    return Scaffold(
      appBar: AppBar(
        title:
            isIndoPk
                ? const Text("Mutashabihat By Para")
                : const Text("Mutashabihat By Juz"),
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
              ).pushNamed(paraMutashabihatPage, arguments: index);
            },
          );
        },
      ),
    );
  }
}

/// This is the page that shows the mutashabihat list
class ParaMutashabihat extends StatelessWidget {
  final int _para;
  final List<Mutashabiha> _mutashabihat = [];
  ParaMutashabihat(this._para, {super.key});

  /// Import the mutashabihat from assets
  Future<List<Mutashabiha>> _importParaMutashabihat() async {
    _mutashabihat.clear();
    _mutashabihat.addAll(await importParaMutashabihat(_para));
    return _mutashabihat;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mutashabihat for ${paraText()} ${_para + 1}"),
      ),
      body: FutureBuilder(
        future: _importParaMutashabihat(),
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
