import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/gestures.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:quran_memorization_helper/models/settings.dart';
import 'package:quran_memorization_helper/models/ayat.dart';
import 'package:quran_memorization_helper/quran_data/para_bounds.dart';
import 'package:quran_memorization_helper/quran_data/surahs.dart';
import 'package:quran_memorization_helper/quran_data/pages.dart';
import 'package:quran_memorization_helper/quran_data/ayat.dart';
import 'package:quran_memorization_helper/quran_data/ayah_offsets.dart';
import 'package:quran_memorization_helper/widgets/mutashabiha_ayat_list_item.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class AyatInPage {
  String text;
  int ayahIdx;
  int surahIdx;
  bool isSurahStart = false;
  bool isFull = true;
  AyatInPage(this.text, this.ayahIdx, this.surahIdx);
}

class ReadQuranPage extends StatefulWidget {
  final ParaAyatModel model;

  const ReadQuranPage(this.model, {super.key});

  @override
  State<StatefulWidget> createState() => _ReadQuranPageState();
}

class _ReadQuranPageState extends State<ReadQuranPage> {
  late final String _para;
  late final int _currentParaIndex;
  final List<List<AyatInPage>> _ayats = [];
  final List<int> _pageNumbers = [];
  List<Mutashabiha> _mutashabihat = [];
  late final ByteBuffer _quranUtf8;
  final ItemPositionsListener _itemPositionListener =
      ItemPositionsListener.create();
  final _repaintNotifier = StreamController<int>.broadcast();

  @override
  void initState() {
    super.initState();

    WakelockPlus.enable(); // disable auto screen turn off
    _currentParaIndex = widget.model.currentPara - 1;
    _para = "Para ${widget.model.currentPara}";
  }

  @override
  void dispose() {
    super.dispose();
    WakelockPlus.disable(); // enable auto screen turn off

    // save position
    final v = _itemPositionListener.itemPositions.value;
    if (v.isNotEmpty) {
      int start = para16LinePageOffsets[_currentParaIndex] - 1;
      Settings.instance.currentReadingPage = start + v.last.index;
    }
  }

  Future<void> _importParaText() async {
    final int para = _currentParaIndex;
    final data = await rootBundle.load("assets/quran.txt");
    _quranUtf8 = data.buffer;
    int start = para16LinePageOffsets[para] - 1;
    int end = para >= 29 ? 548 : para16LinePageOffsets[para + 1] - 1;

    _ayats.clear();

    int prevSurah = -1;
    int absoluteAyahIdx = getFirstAyahOfPara(para);
    bool lastAyahWasIncomplete = false;
    for (int i = start; i < end; ++i) {
      _pageNumbers.add(i);
      final ps = pageOffsets[i];
      final pe = i + 1 >= pageOffsets.length ? null : pageOffsets[i + 1] - ps;
      final pageUtf8 = data.buffer.asUint8List(ps, pe);

      final str = utf8.decode(pageUtf8);
      final ayahs = str.split('\n');
      final bool isLastAyahComplete = str.endsWith('\n');
      List<AyatInPage> ayasInPage = [];
      for (final a in ayahs) {
        if (a.isEmpty) continue;

        int surahIdx = surahForAyah(absoluteAyahIdx);
        if (prevSurah != surahIdx) {
          prevSurah = surahIdx;
          final surahMarker = AyatInPage("", -1, surahIdx);
          surahMarker.isSurahStart = true;
          ayasInPage.add(surahMarker);
        }

        int surahAyahIdx = toSurahAyahOffset(surahIdx, absoluteAyahIdx);
        ayasInPage.add(AyatInPage(a, surahAyahIdx, surahIdx));
        // if we are less than, length this is a complete ayah
        absoluteAyahIdx++;
      }

      if (!isLastAyahComplete) {
        ayasInPage.last.isFull = false;
        absoluteAyahIdx--;
        lastAyahWasIncomplete = true;
      }

      if (lastAyahWasIncomplete) {
        ayasInPage.first.isFull = false;
      }

      _ayats.add(ayasInPage);
    }

    _mutashabihat = await importParaMutashabihas(para);
  }

  void _onAyahTapped(int surahIdx, int ayahIdx, int pageIdx) async {
    bool isFull = true;
    bool isAtPageEnd = false;
    int ayatsArrayIndex = pageIdx - _pageNumbers[0];
    final pageAyas = _ayats[ayatsArrayIndex];
    for (final a in pageAyas) {
      if (a.ayahIdx == ayahIdx && a.surahIdx == surahIdx) {
        isFull = a.isFull;
        if (!isFull) {
          isAtPageEnd = a.ayahIdx == pageAyas.last.ayahIdx;
        }
        break;
      }
    }
    int pageNumberOfTappedAyah = _pageNumbers[ayatsArrayIndex];

    void sendRepainEvent() {
      _repaintNotifier.add(pageNumberOfTappedAyah);
      if (!isFull) {
        if (isAtPageEnd) {
          _repaintNotifier.add(pageNumberOfTappedAyah + 1);
        } else {
          _repaintNotifier.add(pageNumberOfTappedAyah - 1);
        }
      }
    }

    // helper function build actions when clicked on mutashabiha
    List<Widget> buildMutashabihaActions(
        List<Mutashabiha> mutashabihat, AyatOrMutashabiha? aOrM) {
      List<Widget> widgets = [];

      if (aOrM != null) {
        if (aOrM.mutashabiha != null) {
          widgets.add(ListTile(
            title: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete),
                Text("Remove mutashabiha from DB", textAlign: TextAlign.center),
              ],
            ),
            onTap: () {
              widget.model
                  .removeMutashabihas(_currentParaIndex, [aOrM.mutashabiha!]);
              Navigator.of(context).pop();
              sendRepainEvent();
            },
          ));
        } else {
          widgets.add(ListTile(
            title: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete),
                Text("Remove ayah from DB", textAlign: TextAlign.center),
              ],
            ),
            onTap: () {
              // widget.model.addAyahs([aOrM.ayat!]);
              widget.model.removeAyats(_currentParaIndex, [aOrM.getAyahIdx()]);
              Navigator.of(context).pop();
              sendRepainEvent();
            },
          ));
        }
        // close action sheet
      } else {
        widgets.add(ListTile(
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add),
              Text("Add to DB", textAlign: TextAlign.center),
            ],
          ),
          onTap: () {
            if (mutashabihat.isNotEmpty) {
              widget.model
                  .setParaMutashabihas(_currentParaIndex + 1, mutashabihat);
            }
            Navigator.of(context).pop();
            sendRepainEvent();
          },
        ));
      }

      widgets.add(const Divider());
      widgets.add(ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        separatorBuilder: (ctx, index) => const Divider(height: 1),
        itemCount: mutashabihat.length,
        itemBuilder: (ctx, index) {
          return MutashabihaAyatListItem(mutashabiha: mutashabihat[index]);
        },
      ));
      return widgets;
    }

    // int firstPageNumber = para16LinePageOffsets[_currentParaIndex] - 1;

    List<Mutashabiha> mutashabihat = _getMutashabihaAyat(ayahIdx, surahIdx);
    AyatOrMutashabiha? aOrM = _getAyatInDB(ayahIdx, surahIdx);
    if (mutashabihat.isNotEmpty) {
      // If the user clicked on a mutashabiha ayat, we show a bottom sheet
      return await showModalBottomSheet(
        context: context,
        builder: (context) {
          return SizedBox(
            width: MediaQuery.of(context).size.width - 32,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView(
                  children: buildMutashabihaActions(mutashabihat, aOrM)),
            ),
          );
        },
      );
    } else {
      // otherwise we add/remove ayah
      final int abs = toAbsoluteAyahOffset(surahIdx, ayahIdx);
      if (aOrM != null && aOrM.ayat != null) {
        // remove
        widget.model.removeAyats(_currentParaIndex, [abs]);
      } else {
        // add
        final Ayat ayat = getAyahForIdx(abs, _quranUtf8);
        widget.model.addAyahs([ayat]);
      }
      sendRepainEvent();
    }
  }

  List<Mutashabiha> _getMutashabihaAyat(int surahAyahIdx, int surahIdx) {
    List<Mutashabiha> ret = [];
    for (final m in _mutashabihat) {
      if (m.src.surahIdx == surahIdx &&
          m.src.surahAyahIndexes.contains(surahAyahIdx)) {
        ret.add(m);
      }
    }
    return ret;
  }

  bool _isMutashabihaAyat(int surahAyahIdx, int surahIdx) {
    for (final m in _mutashabihat) {
      if (m.src.surahIdx == surahIdx &&
          m.src.surahAyahIndexes.contains(surahAyahIdx)) {
        return true;
      }
    }
    return false;
  }

  bool _isAyatInDB(int surahAyahIdx, int surahIdx) {
    int abs = toAbsoluteAyahOffset(surahIdx, surahAyahIdx);
    for (final a in widget.model.ayahs) {
      if (a.getAyahIdx() == abs) return true;
    }
    return false;
  }

  AyatOrMutashabiha? _getAyatInDB(int surahAyahIdx, int surahIdx) {
    int abs = toAbsoluteAyahOffset(surahIdx, surahAyahIdx);
    for (final a in widget.model.ayahs) {
      if (a.getAyahIdx() == abs) return a;
    }
    return null;
  }

  int _getInitialPageIndex() {
    int p = Settings.instance.currentReadingPage;
    int start = para16LinePageOffsets[_currentParaIndex] - 1;
    int end = _currentParaIndex >= 29
        ? 548
        : para16LinePageOffsets[_currentParaIndex + 1] - 1;
    if (p >= start && p <= end) {
      return p - start;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Reading $_para")),
      body: FutureBuilder(
        future: _importParaText(),
        builder: (context, snapshot) {
          if (_ayats.isEmpty) return const SizedBox.shrink();
          return ScrollablePositionedList.separated(
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemCount: _ayats.length,
            initialScrollIndex: _getInitialPageIndex(),
            itemPositionsListener: _itemPositionListener,
            itemBuilder: (context, index) {
              final pageAyas = _ayats[index];
              return ListTile(
                contentPadding: const EdgeInsets.only(left: 8, right: 8),
                title: QuranPageWidget(
                  pageAyas,
                  _pageNumbers[index],
                  repaintNotifierStream: _repaintNotifier.stream,
                  onAyahTapped: _onAyahTapped,
                  isAyatInDB: _isAyatInDB,
                  isMutashabihaAyat: _isMutashabihaAyat,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class QuranPageWidget extends StatelessWidget {
  final List<AyatInPage> pageAyas;
  final void Function(int surahIdx, int ayahIdx, int pageIdx) onAyahTapped;
  final bool Function(int ayahIdx, int surahIdx) isMutashabihaAyat;
  final bool Function(int ayahIdx, int surahIdx) isAyatInDB;
  final ValueNotifier<int> _rebuilder = ValueNotifier(0);
  final Stream<int> repaintNotifierStream;
  final int pageNumber;

  QuranPageWidget(this.pageAyas, this.pageNumber,
      {required this.onAyahTapped,
      required this.isAyatInDB,
      required this.isMutashabihaAyat,
      required this.repaintNotifierStream,
      super.key}) {
    repaintNotifierStream.listen(_onStreamEvent);
  }

  void _onStreamEvent(int page) {
    if (page == pageNumber) {
      _rebuilder.value++;
    }
  }

  void _tapHandler(int surahIdx, int ayahIdx) async {
    // if the handler returns true, we do a rebuild
    onAyahTapped(surahIdx, ayahIdx, pageNumber);
  }

  static String _toUrduNumber(int num) {
    final Uint16List numMap = Uint16List.fromList([
      0x6F0,
      0x6F0 + 1,
      0x6F0 + 2,
      0x6F0 + 3,
      0x6F0 + 4,
      0x6F0 + 5,
      0x6F0 + 6,
      0x6F0 + 7,
      0x6F0 + 8,
      0x6F0 + 9
    ]);
    final numStr = num.toString();
    String ret = "";
    for (final c in numStr.codeUnits) {
      ret += String.fromCharCode(numMap[c - 48]);
    }
    return ret;
  }

  List<InlineSpan> _buildSpans(List<AyatInPage> pageAyas) {
    List<InlineSpan> spans = [];
    for (final a in pageAyas) {
      if (a.isSurahStart) {
        return spans;
      }
      String ayahNumber;
      if (a.isFull || a.ayahIdx == pageAyas.first.ayahIdx) {
        ayahNumber = String.fromCharCodes([0x6df, 0xF500 + a.ayahIdx]);
      } else {
        ayahNumber = "";
      }
      if (isAyatInDB(a.ayahIdx, a.surahIdx)) {
        spans.add(TextSpan(
            text: "${a.text}$ayahNumber ",
            recognizer: TapGestureRecognizer()
              ..onTap = () => _tapHandler(a.surahIdx, a.ayahIdx),
            style: const TextStyle(inherit: true, color: Colors.red)));
      } else if (isMutashabihaAyat(a.ayahIdx, a.surahIdx)) {
        spans.add(TextSpan(
            text: "${a.text}$ayahNumber ",
            recognizer: TapGestureRecognizer()
              ..onTap = () => _tapHandler(a.surahIdx, a.ayahIdx),
            style: const TextStyle(inherit: true, color: Colors.indigo)));
      } else {
        spans.add(TextSpan(
          text: "${a.text}$ayahNumber ",
          recognizer: TapGestureRecognizer()
            ..onTap = () => _tapHandler(a.surahIdx, a.ayahIdx),
        ));
      }
    }
    return spans;
  }

  List<Widget> _buildPageAyahs(
      List<AyatInPage> pageAyas, BuildContext context) {
    List<Widget> widgets = [];
    for (int i = 0; i < pageAyas.length; ++i) {
      final a = pageAyas[i];
      if (a.isSurahStart) {
        Container c = Container(
          width: MediaQuery.of(context).size.width,
          margin: const EdgeInsets.only(bottom: 16),
          decoration:
              BoxDecoration(border: Border.all(color: Colors.black, width: 2)),
          child: Text(
            /*data:*/ "بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ",
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontFamily: "Al Mushaf",
              fontSize: Settings.instance.fontSize.toDouble(),
              letterSpacing: 0.0,
              wordSpacing: Settings.instance.wordSpacing.toDouble(),
            ),
          ),
        );

        widgets.add(c);
      } else {
        final spans = _buildSpans(pageAyas.sublist(i));
        final text = Text.rich(
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.justify,
          style: TextStyle(
            color: Colors.black,
            fontFamily: "Al Mushaf",
            fontSize: Settings.instance.fontSize.toDouble(),
            letterSpacing: 0.0,
            wordSpacing: Settings.instance.wordSpacing.toDouble(),
          ),
          TextSpan(
            children: spans,
          ),
        );
        widgets.add(text);
        i += spans.length - 1;
      }
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _toUrduNumber(pageNumber + 2),
          style: const TextStyle(
            fontFamily: "Al Mushaf",
            fontSize: 24,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16),
          child: ValueListenableBuilder(
            valueListenable: _rebuilder,
            builder: (context, v, _) {
              return Column(
                children: _buildPageAyahs(pageAyas, context),
              );
            },
          ),
        )
      ],
    );
  }
}
