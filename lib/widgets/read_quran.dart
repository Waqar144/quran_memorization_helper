import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/gestures.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:quran_memorization_helper/models/settings.dart';
import 'package:quran_memorization_helper/models/ayat.dart';
import 'package:quran_memorization_helper/quran_data/surahs.dart';
// import 'package:quran_memorization_helper/quran_data/pages.dart';
import 'package:quran_memorization_helper/quran_data/ayat.dart';
import 'package:quran_memorization_helper/quran_data/ayah_offsets.dart';
import 'package:quran_memorization_helper/widgets/mutashabiha_ayat_list_item.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class LineAyah {
  final int ayahIndex;
  final String text;
  const LineAyah(this.ayahIndex, this.text);
}

class Line {
  final List<LineAyah> lineAyahs;
  const Line(this.lineAyahs);
}

class Page {
  final int pageNum;
  final List<Line> lines;
  const Page(this.pageNum, this.lines);

  static Page fromJson(dynamic json, Uint32List surahAyahStarts) {
    int pageNum = json["pageNum"] as int;
    List<dynamic> lineDatas = json["lines"] as List<dynamic>;
    // List<String> lineDatas = data.split('\n');
    List<Line> lines = [];
    int lastSurahFound = 0;
    for (final lineData in lineDatas) {
      final lineArray = lineData as List<dynamic>;
      List<LineAyah> lineAyahs = [];

      int firstAyahIdx = lineArray.first['idx'] as int;
      int surah = surahAyahStarts.indexOf(firstAyahIdx, lastSurahFound);
      if (surah > 0) {
        lines.add(Line([LineAyah(-surah, "")]));
        lastSurahFound = surah + 1;
      }

      for (final lineArrayItem in lineArray) {
        int ayahIdx = lineArrayItem['idx'] as int;
        final ayahText = lineArrayItem['text'] as String;
        lineAyahs.add(LineAyah(ayahIdx, ayahText));
      }
      lines.add(Line(lineAyahs));
    }
    return Page(pageNum, lines);
  }
}

class ReadQuranWidget extends StatefulWidget {
  final ParaAyatModel model;
  final ScrollController scrollController;

  const ReadQuranWidget(this.model,
      {required this.scrollController, super.key});

  @override
  State<StatefulWidget> createState() => _ReadQuranWidget();
}

class _ReadQuranWidget extends State<ReadQuranWidget>
    with SingleTickerProviderStateMixin {
  List<Line> lines = [];
  List<Page> _pages = [];
  List<Mutashabiha> _mutashabihat = [];
  ByteBuffer? _quranUtf8;
  final _repaintNotifier = StreamController<int>.broadcast();
  // final ItemPositionsListener _itemPositionListener =
  //     ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable(); // disable auto screen turn off
  }

  @override
  void dispose() {
    super.dispose();
    WakelockPlus.disable();

    // save position
    // final v = _itemPositionListener.itemPositions.value;
    // if (v.isNotEmpty) {
    //   int start = para16LinePageOffsets[widget.model.currentPara - 1] - 1;
    //   Settings.instance.currentReadingPage = start + v.last.index;
    // }
  }

  Future<List<Page>> doload() async {
    int para = widget.model.currentPara;
    final data = await rootBundle.loadString("assets/16line/$para.json");
    List<dynamic> pagesList = jsonDecode(data);
    List<Page> pages = [];
    final surahAyahStarts = getSurahAyahStarts();
    for (final p in pagesList) {
      final page = Page.fromJson(p, surahAyahStarts);
      pages.add(page);
    }
    _pages = pages;

    _mutashabihat = await importParaMutashabihas(para - 1);
    return _pages;
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

  (bool isFull, bool atPageStart, bool atPageEnd) _isAyahFull(
      int ayahIdx, int pageNum) {
    bool isFull = true;
    bool isAtPageEnd = false;
    bool isAtPageStart = false;
    int pageIndex = pageNum - _pages[0].pageNum;

    isAtPageEnd =
        _pages[pageIndex].lines.last.lineAyahs.last.ayahIndex == ayahIdx;
    isAtPageStart =
        _pages[pageIndex].lines.first.lineAyahs.first.ayahIndex == ayahIdx;

    if (isAtPageEnd && (pageIndex + 1) < _pages.length) {
      // next page first ayah != this ayah => we have a full ayah
      isFull = _pages[pageIndex + 1].lines.first.lineAyahs.first.ayahIndex !=
          ayahIdx;
    }
    if (isAtPageStart && pageIndex > 0) {
      // prev page last ayah != this ayah => we have a full ayah
      isFull =
          _pages[pageIndex - 1].lines.last.lineAyahs.last.ayahIndex != ayahIdx;
    }
    return (isFull, isAtPageStart, isAtPageEnd);
  }

  void _onAyahTapped(int surahIdx, int ayahIdx, int pageNum) async {
    int currentParaIndex = widget.model.currentPara - 1;
    int absoluteAyah = toAbsoluteAyahOffset(surahIdx, ayahIdx);
    final (isFull, isAtPageStart, isAtPageEnd) =
        _isAyahFull(absoluteAyah, pageNum);

    int pageNumberOfTappedAyah = pageNum;

    void sendRepainEvent() {
      _repaintNotifier.add(pageNumberOfTappedAyah);
      if (!isFull) {
        if (isAtPageEnd) {
          _repaintNotifier.add(pageNumberOfTappedAyah + 1);
        } else if (isAtPageStart) {
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
                  .removeMutashabihas(currentParaIndex, [aOrM.mutashabiha!]);
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
              widget.model.removeAyats(currentParaIndex, [aOrM.getAyahIdx()]);
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
              widget.model.setParaMutashabihas(currentParaIndex, mutashabihat);
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
        widget.model.removeAyats(currentParaIndex, [abs]);
      } else {
        // add
        if (_quranUtf8 == null) {
          final data = await rootBundle.load("assets/quran.txt");
          _quranUtf8 = data.buffer;
        }
        final Ayat ayat = getAyahForIdx(abs, _quranUtf8!);
        widget.model.addAyahs([ayat]);
      }
      sendRepainEvent();
    }
  }

  bool isMobile() {
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.android || platform == TargetPlatform.iOS;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: doload(),
      builder: (context, snapshot) {
        if (_pages.isEmpty) return const SizedBox.shrink();
        return ListView.builder(
          controller: widget.scrollController,
          padding: EdgeInsets.zero,
          itemCount: _pages.length + 1,
          itemBuilder: (ctx, index) {
            if (index >= _pages.length) {
              return Padding(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton.icon(
                  onPressed: () {
                    widget.model.setCurrentPara(widget.model.currentPara + 1);
                    setState(() {
                      _pages.clear();
                    });
                  },
                  icon: const Icon(Icons.arrow_right),
                  label: const Text("Next Para"),
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
                boxShadow: [
                  BoxShadow(
                      color: Theme.of(context).shadowColor,
                      blurRadius: 1,
                      offset: const Offset(1, 1)),
                  BoxShadow(
                      color: Theme.of(context).shadowColor,
                      blurRadius: 1,
                      offset: const Offset(-1, -1))
                ],
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: PageWidget(
                  _pages[index].pageNum,
                  _pages[index].lines,
                  isAyatInDB: _isAyatInDB,
                  onAyahTapped: _onAyahTapped,
                  isMutashabihaAyat: _isMutashabihaAyat,
                  isAyahFull: _isAyahFull,
                  repaintStream: _repaintNotifier.stream,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class PageWidget extends StatefulWidget {
  final int pageNum;
  final List<Line> _pageLines;
  final bool Function(int ayahIdx, int surahIdx) isMutashabihaAyat;
  final bool Function(int ayahIdx, int surahIdx) isAyatInDB;
  final void Function(int surahIdx, int ayahIdx, int pageIdx) onAyahTapped;
  final (bool, bool, bool) Function(int ayahIdx, int pageIdx) isAyahFull;
  final Stream<int> repaintStream;

  const PageWidget(this.pageNum, this._pageLines,
      {required this.isMutashabihaAyat,
      required this.isAyatInDB,
      required this.onAyahTapped,
      required this.repaintStream,
      required this.isAyahFull,
      super.key});

  @override
  State<StatefulWidget> createState() => _PageWidgetState();
}

class _PageWidgetState extends State<PageWidget> {
  StreamSubscription<int>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.repaintStream.listen(_triggerRepaint);
  }

  void _triggerRepaint(int page) {
    if (page == widget.pageNum) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
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

  void _tapHandler(int surahIdx, int ayahIdx) async {
    // if the handler returns true, we do a rebuild
    widget.onAyahTapped(surahIdx, ayahIdx, widget.pageNum);
  }

  Widget getBismillah(int surahIdx) {
    surahIdx = -surahIdx;
    final style = TextStyle(
      color: Colors.black,
      fontFamily: "Al Mushaf",
      fontSize: Settings.instance.fontSize.toDouble(),
      letterSpacing: 0.0,
      wordSpacing: Settings.instance.wordSpacing.toDouble(),
    );
    SurahData surahData = surahDataForIdx(surahIdx, arabic: true);
    return Container(
      width: MediaQuery.of(context).size.width,
      // margin: const EdgeInsets.all(8),
      decoration:
          BoxDecoration(border: Border.all(color: Colors.black, width: 1)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        textDirection: TextDirection.rtl,
        children: [
          Text(
            "\uFD3F${surahData.name}\uFD3E",
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: style,
          ),
          Text(
            /*data:*/ "بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ",
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: style,
          ),
          Text(
            "\uFD3F${_toUrduNumber(surahData.ayahCount)}\uFD3E",
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: style,
          ),
        ],
      ),
    );
  }

  bool _shouldDrawAyahEndMarker(int ayahIdx, int lineIdx) {
    Line l = widget._pageLines[lineIdx];
    // If we have multiple ayahs in the line, and this not the last then this is full ayah
    if (l.lineAyahs.last.ayahIndex != ayahIdx) {
      return true;
    } else {
      bool isLast = lineIdx == widget._pageLines.length - 1;
      if (isLast) {
        return widget.isAyahFull(ayahIdx, widget.pageNum).$1;
      } else {
        if (widget._pageLines[lineIdx + 1].lineAyahs.first.ayahIndex !=
            ayahIdx) {
          return true;
        }
      }
    }
    return false;
  }

  Widget _buildLine(Line line, int lineIdx) {
    List<InlineSpan> spans = [];
    List<int> ayahMarkerIdxes = [];
    for (final a in line.lineAyahs) {
      int surahIdx = surahForAyah(a.ayahIndex);
      int surahAyahIdx = toSurahAyahOffset(surahIdx, a.ayahIndex);

      if (widget.isAyatInDB(surahAyahIdx, surahIdx)) {
        spans.add(TextSpan(
            text: a.text.trim(),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _tapHandler(surahIdx, surahAyahIdx),
            style: const TextStyle(inherit: true, color: Colors.red)));
      } else if (widget.isMutashabihaAyat(surahAyahIdx, surahIdx)) {
        spans.add(TextSpan(
            text: a.text.trim(),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _tapHandler(surahIdx, surahAyahIdx),
            style: const TextStyle(inherit: true, color: Colors.indigo)));
      } else {
        spans.add(TextSpan(
            recognizer: TapGestureRecognizer()
              ..onTap = () => _tapHandler(surahIdx, surahAyahIdx),
            text: a.text));
      }

      if (_shouldDrawAyahEndMarker(a.ayahIndex, lineIdx)) {
        bool hasRukuMarker = a.text.lastIndexOf("\uE022") != -1;
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            baseline: TextBaseline.ideographic,
            child: Container(
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(),
                color: hasRukuMarker ? Colors.amber : Colors.transparent,
              ),
              alignment: Alignment.center,
              width: 15,
              height: 15,
              child: FittedBox(
                fit: BoxFit.contain,
                child: Text(_toUrduNumber(surahAyahIdx + 1),
                    softWrap: false, textDirection: TextDirection.rtl),
              ),
            ),
          ),
        );
        ayahMarkerIdxes.add(spans.length - 1);
      }
    }

    List<InlineSpan> widgetSpans = [];
    for (final am in ayahMarkerIdxes) {
      widgetSpans.add(spans[am]);
    }
    widgetSpans = widgetSpans.reversed.toList();
    int i = 0;
    for (final am in ayahMarkerIdxes) {
      spans.removeAt(am);
      spans.insert(am, widgetSpans[i++]);
    }

    return Text.rich(
      TextSpan(children: spans),
      textDirection: TextDirection.rtl,
      style: const TextStyle(
        color: Colors.black,
        fontFamily: "Al Mushaf",
        fontSize: 24,
        letterSpacing: 0,
        wordSpacing: 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          (widget.pageNum + 1).toString(),
          style: const TextStyle(fontSize: 12),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8, right: 8),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            separatorBuilder: (ctx, idx) => const Divider(
              color: Colors.grey,
              height: 1,
            ),
            shrinkWrap: true,
            itemCount: widget._pageLines.length,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (ctx, idx) {
              final pageLine = widget._pageLines[idx];
              if (pageLine.lineAyahs.first.ayahIndex < 0) {
                return getBismillah(pageLine.lineAyahs.first.ayahIndex);
              }
              return SizedBox(
                height: 46,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: _buildLine(pageLine, idx),
                ),
              );
            },
          ),
        )
      ],
    );
  }
}
