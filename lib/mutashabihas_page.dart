import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'ayat.dart';
import 'page_constants.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'ayah_offsets.dart';
import 'settings.dart';
import 'para_bounds.dart';
import 'surahs.dart';

class MutashabihasPage extends StatelessWidget {
  const MutashabihasPage({super.key});

  @override
  Widget build(BuildContext context) {
    // final NavigatorState nav = Navigator.of(context);
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
              Navigator.of(context)
                  .pushNamed(paraMutashabihasPage, arguments: index);
            },
          );
        },
      ),
    );
  }
}

class MutashabihaAyat extends Ayat {
  final List<int> surahAyahIndexes;
  final int paraIdx;
  final int surahIdx;
  MutashabihaAyat(
      this.paraIdx, this.surahIdx, this.surahAyahIndexes, super.text);

  String surahAyahIndexesString() {
    return surahAyahIndexes.fold("", (String s, int v) {
      return s.isEmpty ? "${v + 1}" : "$s, ${v + 1}";
    });
  }
}

class Mutashabiha {
  final MutashabihaAyat src;
  final List<MutashabihaAyat> matches;
  Mutashabiha(this.src, this.matches);
}

String _getContext(
    int contextType, int ayahIdx, String text, final ByteBuffer quranTextUtf8) {
  if (contextType == 1) {
    final range = getAyahRange(ayahIdx - 1);
    String prevAyahText =
        utf8.decode(quranTextUtf8.asUint8List(range.start, range.len));
    final words = prevAyahText.split(' ');
    List<String> toshow = [];
    for (final word in words.reversed) {
      toshow.add(word);
      if (toshow.length > 5) {
        break;
      }
    }
    toshow = toshow.reversed.toList();
    final String threeDot = toshow.length == words.length ? "" : "...";
    return "$threeDot${toshow.join(' ')}$ayahSeparator$text";
  } else if (contextType == 2) {
    final range = getAyahRange(ayahIdx + 1);
    String nextAyahText =
        utf8.decode(quranTextUtf8.asUint8List(range.start, range.len));
    final words = nextAyahText.split(' ');
    List<String> toshow = [];
    for (final word in words) {
      toshow.add(word);
      if (toshow.length > 5) {
        break;
      }
    }
    final String threeDot = toshow.length == words.length ? "" : "...";
    return "$text$ayahSeparator${toshow.join(' ')}$threeDot";
  }
  throw "Invalid context $contextType";
}

MutashabihaAyat _ayatFromJsonObj(
    dynamic m, final ByteBuffer quranTextUtf8, int ctx) {
  try {
    List<int> ayahIdxes;
    if (m["ayah"] is List) {
      ayahIdxes = [for (final a in m["ayah"]) a as int];
    } else {
      ayahIdxes = [m["ayah"] as int];
    }
    String text = "";
    List<int> surahAyahIdxes = [];
    int surahIdx = -1;
    int paraIdx = -1;
    for (final ayahIdx in ayahIdxes) {
      final ayahRange = getAyahRange(ayahIdx);
      final textUtf8 =
          quranTextUtf8.asUint8List(ayahRange.start, ayahRange.len);
      text += utf8.decode(textUtf8);
      if (ayahIdx != ayahIdxes.last) {
        text += ayahSeparator;
      }
      if (surahIdx == -1) {
        surahIdx = surahForAyah(ayahIdx);
        paraIdx = paraForAyah(ayahIdx);
      }
      surahAyahIdxes.add(toSurahAyahOffset(surahIdx, ayahIdx));
    }

    const int preContext = 1;
    const int postContext = 2;
    if (ctx == preContext) {
      text = _getContext(ctx, ayahIdxes.first, text, quranTextUtf8);
    } else if (ctx == postContext) {
      text = _getContext(ctx, ayahIdxes.last, text, quranTextUtf8);
    }
    return MutashabihaAyat(paraIdx, surahIdx, surahAyahIdxes, text);
  } catch (e) {
    // print(e);
    rethrow;
  }
}

class AyatListItemWithMetadata extends StatelessWidget {
  final MutashabihaAyat _ayah;
  final VoidCallback? onTap;
  final Widget? leading;
  final ValueNotifier<bool> doRebuild = ValueNotifier(false);
  AyatListItemWithMetadata(this._ayah, {this.onTap, this.leading, super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: doRebuild,
        builder: (context, value, _) {
          return ListTile(
            leading: leading,
            title: Text(
              _ayah.text,
              softWrap: true,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                  fontFamily: "Al Mushaf",
                  fontSize: Settings.instance.fontSize.toDouble(),
                  letterSpacing: 0.0,
                  wordSpacing: Settings.instance.wordSpacing.toDouble()),
            ),
            subtitle: Text(
                "${surahNameForIdx(_ayah.surahIdx)}:${_ayah.surahAyahIndexesString()} - Para: ${_ayah.paraIdx + 1}"),
            onTap: onTap,
          );
        });
  }
}

class MutashabihaAyatListItem extends StatelessWidget {
  final Mutashabiha mutashabiha;
  final ValueNotifier<bool> _showMatches = ValueNotifier(false);
  MutashabihaAyatListItem({super.key, required this.mutashabiha});

  void _onTap() {
    _showMatches.value = !_showMatches.value;
  }

  Widget _buildMatches(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.background,
          border: Border.all(color: theme.colorScheme.inversePrimary, width: 1),
          boxShadow: [
            BoxShadow(
                color: theme.shadowColor,
                blurRadius: 4,
                offset: const Offset(4, 2)),
          ],
        ),
        child: ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          separatorBuilder: (ctx, index) => const Divider(height: 1),
          itemCount: mutashabiha.matches.length,
          itemBuilder: (ctx, index) {
            return AyatListItemWithMetadata(mutashabiha.matches[index]);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AyatListItemWithMetadata(
          mutashabiha.src,
          onTap: _onTap,
          leading: ValueListenableBuilder(
            valueListenable: _showMatches,
            builder: (ctx, value, _) {
              return Icon(value ? Icons.expand_more : Icons.chevron_right);
            },
          ),
        ),
        ValueListenableBuilder(
          valueListenable: _showMatches,
          builder: (ctx, value, _) {
            if (!value) {
              return const SizedBox.shrink();
            }
            return _buildMatches(Theme.of(context));
          },
        )
      ],
    );
  }
}

class ParaMutashabihas extends StatelessWidget {
  final int _para;
  const ParaMutashabihas(this._para, {super.key});

  Future<List<Mutashabiha>> _importParaMutashabihas() async {
    final mutashabihasJsonBytes =
        await rootBundle.load("assets/mutashabiha_data.json");
    final mutashabihasJson =
        utf8.decode(mutashabihasJsonBytes.buffer.asUint8List());
    final map = jsonDecode(mutashabihasJson) as Map<String, dynamic>;
    int paraNum = _para + 1;
    final list = map[paraNum.toString()] as List<dynamic>;

    List<Mutashabiha> mutashabihas = [];
    final ByteData data = await rootBundle.load("assets/quran.txt");
    for (final m in list) {
      if (m == null) continue;
      try {
        int ctx = (m["ctx"] as int?) ?? 0;
        MutashabihaAyat src = _ayatFromJsonObj(m["src"], data.buffer, ctx);
        List<MutashabihaAyat> matches = [];
        for (final match in m["muts"]) {
          matches.add(_ayatFromJsonObj(match, data.buffer, ctx));
        }
        mutashabihas.add(Mutashabiha(src, matches));
      } catch (e) {
        rethrow;
      }
    }
    return mutashabihas;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Mutashabihas for Para ${_para + 1}")),
      body: FutureBuilder(
        future: _importParaMutashabihas(),
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (data == null) {
            return const SizedBox.shrink();
          } else if (data.isEmpty) {
            return const SizedBox.shrink();
          }
          return ListView.separated(
            separatorBuilder: (ctx, index) => const Divider(height: 1),
            itemCount: data.length,
            itemBuilder: (ctx, index) {
              return MutashabihaAyatListItem(mutashabiha: data[index]);
            },
          );
        },
      ),
    );
  }
}
