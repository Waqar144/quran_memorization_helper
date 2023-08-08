import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/gestures.dart';
import 'dart:convert';
import 'package:quran_memorization_helper/models/settings.dart';
import 'package:quran_memorization_helper/quran_data/para_bounds.dart';
import 'package:quran_memorization_helper/quran_data/surahs.dart';
import 'package:quran_memorization_helper/quran_data/pages.dart';

class AyatInPage {
  String text;
  int ayahIdx;
  AyatInPage(this.text, this.ayahIdx);
}

class ReadQuranPage extends StatefulWidget {
  final int _paraNum;

  const ReadQuranPage(this._paraNum, {super.key});

  @override
  State<StatefulWidget> createState() => _ReadQuranPageState();
}

class _ReadQuranPageState extends State<ReadQuranPage> {
  late final String _para;
  final List<List<AyatInPage>> _ayats = [];
  final List<String> _pageNumbers = [];

  @override
  void initState() {
    super.initState();

    _para = "Para ${widget._paraNum}";
  }

  String toUrduNumber(int num) {
    const List<String> numMap = [
      "٠",
      "۱",
      "٢",
      "٣",
      "٤",
      "٥",
      "٦",
      "٧",
      "۸",
      "٩"
    ];
    final numStr = num.toString();
    String ret = "";
    for (final c in numStr.codeUnits) {
      ret += numMap[c - 48];
    }
    return ret;
  }

  Future<void> _importParaText(int para) async {
    final data = await rootBundle.load("assets/quran.txt");
    int start = para16LinePageOffsets[para - 1] - 1;
    int end = para >= 30 ? 548 : para16LinePageOffsets[para] - 1;

    _ayats.clear();

    int absoluteAyahIdx = getFirstAyahOfPara(para - 1);
    for (int i = start; i < end; ++i) {
      _pageNumbers.add(toUrduNumber(i + 2));
      final ps = pageOffsets[i];
      final pe = i + 1 >= pageOffsets.length ? null : pageOffsets[i + 1] - ps;
      final pageUtf8 = data.buffer.asUint8List(ps, pe);

      final str = utf8.decode(pageUtf8);
      final ayahs = str.split('\n');
      List<AyatInPage> ayas = [];
      for (final a in ayahs) {
        if (a.isEmpty) continue;
        int surahIdx = surahForAyah(absoluteAyahIdx);
        int surahAyahIdx = toSurahAyahOffset(surahIdx, absoluteAyahIdx);
        ayas.add(AyatInPage(a, surahAyahIdx));
        absoluteAyahIdx++;
      }
      _ayats.add(ayas);
    }
  }

  void _onDone(BuildContext context) {
    // List<Ayat> selected = [
  }

  void ontap(int ayahIdx) {
    print("Tapped: $ayahIdx");
    showModalBottomSheet(
        context: context,
        elevation: 5.0,
        builder: (context) {
          return SizedBox(
            width: MediaQuery.of(context).size.width - 32,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  ListTile(
                    title: const Text(
                      "Hello what is a long action",
                      textAlign: TextAlign.center,
                    ),
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const Text("Hello"),
                ],
              ),
            ),
          );
        });
  }

  List<InlineSpan> buildSpans(List<AyatInPage> pageAyas) {
    List<InlineSpan> spans = [];
    for (final a in pageAyas) {
      // int ayahNum = a.ayahIdx + 1;
      String x = String.fromCharCodes([0x6df, 0xF500 + a.ayahIdx]);
      // print("$ayahNum --- '${a.text}'");
      spans.add(TextSpan(
        text: "${a.text}$x ",
        recognizer: TapGestureRecognizer()..onTap = () => ontap(a.ayahIdx),
      ));
      // spans.add(TextSpan(text: "$x"));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reading $_para"),
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
          return ListView.separated(
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemCount: _ayats.length,
            itemBuilder: (context, index) {
              final pageAyas = _ayats[index];
              return ListTile(
                contentPadding: const EdgeInsets.only(left: 8, right: 8),
                title: Column(
                  children: [
                    Text(_pageNumbers[index]),
                    Text.rich(
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: "Al Mushaf",
                        fontSize: Settings.instance.fontSize.toDouble(),
                        letterSpacing: 0.0,
                        wordSpacing: Settings.instance.wordSpacing.toDouble(),
                      ),
                      TextSpan(
                        children: buildSpans(pageAyas),
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
