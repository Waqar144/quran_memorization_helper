import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:quran_memorization_helper/models/settings.dart';
import 'package:quran_memorization_helper/models/ayat.dart';
import 'package:quran_memorization_helper/quran_data/surahs.dart';
import 'package:quran_memorization_helper/quran_data/para_bounds.dart';
import 'package:quran_memorization_helper/quran_data/ayat.dart';
import 'package:quran_memorization_helper/quran_data/should_add_spaces.dart';
import 'package:quran_memorization_helper/widgets/mutashabiha_ayat_list_item.dart';
import 'package:quran_memorization_helper/widgets/tap_and_longpress_gesture_recognizer.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

final _markedWordStyleLight = TextStyle(
  inherit: true,
  backgroundColor: Colors.red.shade100,
  color: Colors.red,
);
final _markedWordStyleDark = TextStyle(
  inherit: true,
  backgroundColor: Colors.red.withAlpha(80),
  color: Colors.red,
);

TextStyle _markedWordStyle(bool dark) {
  if (dark) {
    return _markedWordStyleDark;
  }
  return _markedWordStyleLight;
}

final _markedAyahBGStyleLight = TextStyle(
  inherit: true,
  backgroundColor: Colors.red.shade100,
);
final _markedAyahBGStyleDark = TextStyle(
  inherit: true,
  backgroundColor: Colors.red.withAlpha(80),
);

TextStyle _markedAyahBGStyle(bool dark) {
  if (dark) {
    return _markedAyahBGStyleDark;
  }
  return _markedAyahBGStyleLight;
}

final _markedMutAyahBGStyleLight = TextStyle(
  inherit: true,
  color: Colors.indigo,
  backgroundColor: Colors.red.shade100,
);
final _markedMutAyahBGStyleDark = _markedMutAyahBGStyleLight.copyWith(
  color: Colors.indigo.shade200,
  backgroundColor: Colors.red.withAlpha(80),
);
TextStyle _markedMutAyahBGStyle(bool dark) {
  if (dark) {
    return _markedMutAyahBGStyleDark;
  }
  return _markedMutAyahBGStyleLight;
}

const TextStyle _mutStyleLight = TextStyle(inherit: true, color: Colors.indigo);
TextStyle _mutStyle(bool dark) {
  if (dark) {
    return _mutStyleLight.copyWith(color: Colors.indigo.shade200);
  }
  return _mutStyleLight;
}

class TranslationTile extends StatefulWidget {
  final String translation;
  final String metadata;
  final bool expanded;
  const TranslationTile(this.translation,
      {required this.metadata, required this.expanded, super.key});

  @override
  State<StatefulWidget> createState() => _TranslationTileState();
}

class _TranslationTileState extends State<TranslationTile> {
  late final ValueNotifier<bool> expanded;

  @override
  void initState() {
    expanded = ValueNotifier(widget.expanded);
    super.initState();
  }

  @override
  dispose() {
    expanded.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: expanded,
      builder: (context, value, _) {
        return ListTile(
          leading: widget.expanded
              ? null
              : Icon(!value ? Icons.chevron_right : Icons.expand_more),
          title: !value
              ? const Text("Show Translation")
              : Column(
                  children: [
                    Text(
                      widget.metadata,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    Text(
                      widget.translation,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                          fontFamily: "Urdu",
                          fontSize: 22,
                          letterSpacing: 0.0,
                          height: 1.8),
                    ),
                  ],
                ),
          onTap: () {
            if (widget.expanded) return;
            expanded.value = !expanded.value;
          },
        );
      },
    );
  }
}

class LongPressActionSheet extends StatefulWidget {
  final Widget? mutashabihaList;
  final ByteBuffer transUtf8;
  final List<int> transLineOffsets;
  final int currentParaIdx;

  /// absoluteAyah index of tapped ayah
  final int tappedAyahIdx;

  const LongPressActionSheet({
    super.key,
    required this.mutashabihaList,
    required this.transUtf8,
    required this.transLineOffsets,
    required this.currentParaIdx,
    required this.tappedAyahIdx,
  });

  @override
  State<StatefulWidget> createState() => _LongPressActionSheetState();
}

class _LongPressActionSheetState extends State<LongPressActionSheet> {
  late final int _paraFirstAyah;
  late final int _totalAyahsInPara;
  late PageController _controller;

  @override
  void initState() {
    _totalAyahsInPara = paraAyahCount[widget.currentParaIdx];
    _paraFirstAyah = getFirstAyahOfPara(widget.currentParaIdx);
    int currentAyah = widget.tappedAyahIdx - _paraFirstAyah;
    _controller = PageController(initialPage: currentAyah);

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String surahAyahText(int ayahIdx) {
    int surah = surahForAyah(ayahIdx);
    int ayah = toSurahAyahOffset(surah, ayahIdx);
    return "${surahNameForIdx(surah)}:${ayah + 1}";
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      reverse: true,
      itemCount: _totalAyahsInPara,
      controller: _controller,
      itemBuilder: (context, index) {
        int ayah = _paraFirstAyah + index;
        int s = widget.transLineOffsets[ayah];
        int e = widget.transLineOffsets[ayah + 1];
        String translation =
            utf8.decode(widget.transUtf8.asUint8List(s, e - s));
        String metadata = surahAyahText(ayah);

        // if mutashabiha is null, we always expand
        bool expanded = widget.mutashabihaList == null ||
            // else if user has swiped, then we expand
            (widget.mutashabihaList != null && widget.tappedAyahIdx != ayah);
        final translationWidget = TranslationTile(translation,
            metadata: metadata, expanded: expanded);

        if (widget.tappedAyahIdx == ayah && widget.mutashabihaList != null) {
          return ListView(
            children: [
              translationWidget,
              const Divider(),
              widget.mutashabihaList!
            ],
          );
        }

        return ListView(
          children: [
            translationWidget,
          ],
        );
      },
    );
  }
}

class CustomPageViewScrollPhysics extends ScrollPhysics {
  const CustomPageViewScrollPhysics({super.parent});

  @override
  CustomPageViewScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomPageViewScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 100,
        stiffness: 100,
        damping: 1.2,
      );
}

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

  static Page fromJson(dynamic json, List<int> surahAyahStarts) {
    int pageNum = json["pageNum"] as int;
    List<dynamic> lineDatas = json["lines"] as List<dynamic>;
    List<Line> lines = [];
    for (final lineData in lineDatas) {
      final lineArray = lineData as List<dynamic>;
      List<LineAyah> lineAyahs = [];

      int firstAyahIdx = lineArray.first['idx'] as int;
      if (surahAyahStarts.lastOrNull == firstAyahIdx) {
        int surah = getSurahAyahStarts().indexOf(surahAyahStarts.last);
        assert(surah != -1);
        lines.add(Line([LineAyah(-surah, "")]));
        surahAyahStarts.removeLast();
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
  final PageController pageController;

  const ReadQuranWidget(this.model, {required this.pageController, super.key});

  @override
  State<StatefulWidget> createState() => _ReadQuranWidget();
}

class _ReadQuranWidget extends State<ReadQuranWidget>
    with SingleTickerProviderStateMixin {
  List<Line> lines = [];
  List<Page> _pages = [];
  List<Mutashabiha> _mutashabihat = [];
  ByteBuffer? _quranUtf8;
  ByteBuffer? _transUtf8;
  List<int>? _transLineOffsets;
  final _repaintNotifier = StreamController<int>.broadcast();
  Timer? _nextParaLoadTimer;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable(); // disable auto screen turn off
  }

  @override
  void dispose() {
    super.dispose();
    WakelockPlus.disable();
  }

  @override
  void didUpdateWidget(ReadQuranWidget old) {
    _pages.clear();
    super.didUpdateWidget(old);
  }

  Future<List<Page>> doload() async {
    int para = widget.model.currentPara;
    final data = await rootBundle.loadString("assets/16line/$para.json");
    List<dynamic> pagesList = jsonDecode(data);
    List<Page> pages = [];
    List<int> surahAyahStarts =
        surahAyahOffsetsForPara(para - 1).reversed.toList();
    for (final p in pagesList) {
      pages.add(Page.fromJson(p, surahAyahStarts));
    }
    _pages = pages;

    // we lazy load the mutashabiha ayat text
    _mutashabihat = await importParaMutashabihas(para - 1, null);
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

  Ayat? _getAyatInDB(int surahAyahIdx, int surahIdx) {
    int abs = toAbsoluteAyahOffset(surahIdx, surahAyahIdx);
    for (final a in widget.model.ayahs) {
      if (a.ayahIdx == abs) return a;
    }
    return null;
  }

  String _getFullAyahText(int ayahIdx, int pageNum) {
    int pageIndex = pageNum - _pages[0].pageNum;
    int startPage = pageIndex == 0 ? pageIndex : pageIndex - 1;
    int endPage = pageNum == _pages.last.pageNum ? pageIndex : pageIndex + 1;

    bool foundStart = false;
    String text = "";

    for (int p = startPage; p <= endPage; p++) {
      Page page = _pages[p];
      for (final line in page.lines) {
        for (final lineAyah in line.lineAyahs) {
          if (lineAyah.ayahIndex == ayahIdx) {
            if (!foundStart) {
              foundStart = true;
            }
            text += lineAyah.text;
            text += "\u200c";
          } else {
            if (foundStart) {
              break;
            }
          }
        }
      }
    }
    return text;
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

  void _onAyahLongPressed(
      int surahIdx, int ayahIdx, int wordIdx, int pageNum) async {
    List<Mutashabiha> mutashabihat = _getMutashabihaAyat(ayahIdx, surahIdx);

    if (_quranUtf8 == null) {
      final data = await rootBundle.load("assets/quran.txt");
      _quranUtf8 = data.buffer;
    }

    if (_transUtf8 == null) {
      final data = await rootBundle.load("assets/ur.jalandhry.txt");
      _transUtf8 = data.buffer;

      _transLineOffsets = [];
      _transLineOffsets!.add(0);
      int start = 0;
      final utf = _transUtf8!.asUint8List();
      int next = utf.indexOf(10);
      while (next != -1) {
        _transLineOffsets!.add(next);

        start = next + 1;
        next = utf.indexOf(10, start);
      }
    }

    for (int i = 0; i < mutashabihat.length; ++i) {
      mutashabihat[i].loadText(_quranUtf8!);
    }

    int tappedAyah = toAbsoluteAyahOffset(surahIdx, ayahIdx);

    Widget? mutashabihaWidget;
    if (mutashabihat.isNotEmpty) {
      mutashabihaWidget = ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        separatorBuilder: (ctx, index) => const Divider(height: 1),
        itemCount: mutashabihat.length,
        itemBuilder: (ctx, index) {
          return MutashabihaAyatListItem(mutashabiha: mutashabihat[index]);
        },
      );
    }

    if (!mounted) return;

    return await showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: LongPressActionSheet(
              mutashabihaList: mutashabihaWidget,
              transUtf8: _transUtf8!,
              transLineOffsets: _transLineOffsets!,
              currentParaIdx: widget.model.currentPara - 1,
              tappedAyahIdx: tappedAyah,
            ),
          ),
        );
      },
    );
  }

  void _onAyahTapped(int surahIdx, int ayahIdx, int wordIdx, int pageNum,
      bool longPress) async {
    if (longPress) {
      _onAyahLongPressed(surahIdx, ayahIdx, wordIdx, pageNum);
      return;
    }

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

    // List<Mutashabiha> mutashabihat = _getMutashabihaAyat(ayahIdx, surahIdx);
    Ayat? ayatInDb = _getAyatInDB(ayahIdx, surahIdx);
    // otherwise we add/remove ayah
    final int abs = toAbsoluteAyahOffset(surahIdx, ayahIdx);
    if (ayatInDb != null && ayatInDb.markedWords.contains(wordIdx)) {
      // remove
      widget.model.removeAyats(currentParaIndex, abs, wordIdx);
    } else {
      // add
      Ayat ayat = Ayat("", [wordIdx], ayahIdx: abs);
      widget.model.addAyahs([ayat]);
    }
    sendRepainEvent();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: doload(),
      builder: (context, snapshot) {
        if (_pages.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverToBoxAdapter(
          child: SizedBox(
            height: 785,
            child: NotificationListener<OverscrollNotification>(
              onNotification: (noti) {
                if (noti.depth == 0) {
                  int dir = noti.overscroll >= 0 ? 1 : -1;
                  int currentPara = widget.model.currentPara;
                  int nextPara = currentPara + dir;

                  if (nextPara <= 0) {
                    nextPara = 30;
                  } else if (nextPara > 30) {
                    nextPara = 1;
                  }

                  // debounce as there are a lot of notifications
                  _nextParaLoadTimer?.cancel();
                  _nextParaLoadTimer =
                      Timer(const Duration(milliseconds: 50), () {
                    bool lastpage = dir < 0;
                    widget.model
                        .setCurrentPara(nextPara, showLastPage: lastpage);
                  });
                }
                return false;
              },
              child: PageView.builder(
                controller: widget.pageController,
                reverse: true,
                itemCount: _pages.length,
                scrollBehavior: const ScrollBehavior()
                  ..copyWith(overscroll: false),
                physics: const CustomPageViewScrollPhysics(),
                itemBuilder: (ctx, index) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: PageWidget(
                      _pages[index].pageNum,
                      _pages[index].lines,
                      getAyatInDB: _getAyatInDB,
                      onAyahTapped: _onAyahTapped,
                      isMutashabihaAyat: _isMutashabihaAyat,
                      isAyahFull: _isAyahFull,
                      getFullAyahText: _getFullAyahText,
                      repaintStream: _repaintNotifier.stream,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class PageWidget extends StatefulWidget {
  final int pageNum;
  final List<Line> _pageLines;
  final bool Function(int ayahIdx, int surahIdx) isMutashabihaAyat;
  final Ayat? Function(int ayahIdx, int surahIdx) getAyatInDB;
  final void Function(
          int surahIdx, int ayahIdx, int wordIdx, int pageIdx, bool longPress)
      onAyahTapped;
  final (bool, bool, bool) Function(int ayahIdx, int pageIdx) isAyahFull;
  final String Function(int ayahIdx, int pageNum) getFullAyahText;
  final Stream<int> repaintStream;

  const PageWidget(this.pageNum, this._pageLines,
      {required this.isMutashabihaAyat,
      required this.getAyatInDB,
      required this.onAyahTapped,
      required this.repaintStream,
      required this.isAyahFull,
      required this.getFullAyahText,
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

  void _tapHandler(
      int surahIdx, int ayahIdx, int wordIdx, bool longPress) async {
    widget.onAyahTapped(surahIdx, ayahIdx, wordIdx, widget.pageNum, longPress);
  }

  Widget getTwoLinesBismillah(int surahIdx, TextStyle style) {
    SurahData surahData = surahDataForIdx(surahIdx, arabic: true);

    return Column(
      textDirection: TextDirection.rtl,
      children: [
        // surah name and ayah count
        Container(
          height: 46,
          decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.4),
              border:
                  Border.all(color: Theme.of(context).dividerColor, width: 1)),
          child: Row(
            children: [
              Text(
                "\uFD3Fآیاتھا ${_toUrduNumber(surahData.ayahCount)}\uFD3E",
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: style,
              ),
              const Spacer(),
              Text(
                "\uFD3Fسورۃ ${surahData.name}\uFD3E",
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: style,
              ),
            ],
          ),
        ),
        // bismillah
        Container(
          height: 46,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.4),
            border: Border.all(color: Theme.of(context).dividerColor, width: 1),
          ),
          child: Text(
            /*data:*/ "بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ",
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: style,
          ),
        )
      ],
    );
  }

  Widget getBismillah(int surahIdx) {
    surahIdx = -surahIdx;
    final style = TextStyle(
      color: Theme.of(context).textTheme.bodyMedium?.color,
      fontFamily: "Al Mushaf",
      fontSize: Settings.instance.fontSize.toDouble(),
      letterSpacing: 0.0,
      wordSpacing: Settings.instance.wordSpacing.toDouble(),
    );

    // 30th para ?
    if (widget.pageNum >= 528) {
      if (surahHas2LineHeadress(surahIdx)) {
        return getTwoLinesBismillah(surahIdx, style);
      }
    } else if (widget._pageLines.length == 15) {
      return getTwoLinesBismillah(surahIdx, style);
    }

    SurahData surahData = surahDataForIdx(surahIdx, arabic: true);
    final isSurahTawba = surahIdx == 8;
    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.4),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1)),
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
            isSurahTawba ? "-" : "بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ",
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

  static bool isSajdaAyat(int surahIndex, int ayahIndex) {
    return switch (surahIndex) {
      6 => ayahIndex == 205,
      12 => ayahIndex == 14,
      15 => ayahIndex == 49,
      16 => ayahIndex == 108,
      18 => ayahIndex == 57,
      21 => ayahIndex == 17,
      24 => ayahIndex == 59,
      26 => ayahIndex == 25,
      31 => ayahIndex == 14,
      37 => ayahIndex == 23,
      40 => ayahIndex == 37,
      52 => ayahIndex == 61,
      83 => ayahIndex == 20,
      95 => ayahIndex == 18,
      _ => false
    };
  }

  static (String marker, bool isSajda) getAyahEndMarkerGlyphCode(
      int surahIndex, int ayahIndex) {
    if (isSajdaAyat(surahIndex, ayahIndex)) {
      return (
        switch (surahIndex) {
          6 => '\uf68e',
          12 => '\uf681',
          15 => '\uf688',
          16 => '\uf68d',
          18 => '\uf689',
          21 => '\uf682',
          24 => '\uf68a',
          26 => '\uf686',
          31 => '\uf68b',
          37 => '\uf685',
          40 => '\uf687',
          52 => '\uf68c',
          83 => '\uf684',
          95 => '\uf683',
          _ => throw "Invalid sajda ayah"
        },
        true
      );
    }
    return (String.fromCharCode(0xF500 + ayahIndex), false);
  }

  // Finds the correct position of the first word of the line
  // in the full ayah text
  static int getFirstWordIndex(
      List<String> fullAyahWords, List<String> currentLineWords,
      {int start = -1}) {
    String first = currentLineWords.first;
    int idx = fullAyahWords.indexOf(first, start);
    int c = 0;
    const int maxMatch = 4;
    for (int i = idx;
        i < fullAyahWords.length && c < currentLineWords.length;
        ++i, ++c) {
      String next = currentLineWords[c];
      if (fullAyahWords[i] != next) {
        return getFirstWordIndex(fullAyahWords, currentLineWords, start: i + 1);
      }
      if (c >= maxMatch) break;
    }
    return idx;
  }

  List<TextSpan> _buildLineSpans(Line line, int lineIdx) {
    List<TextSpan> spans = [];
    for (final a in line.lineAyahs) {
      final int surahIdx = surahForAyah(a.ayahIndex);
      final int surahAyahIdx = toSurahAyahOffset(surahIdx, a.ayahIndex);
      final Ayat? ayahInDb = widget.getAyatInDB(surahAyahIdx, surahIdx);
      final bool isMutashabihaAyat =
          widget.isMutashabihaAyat(surahAyahIdx, surahIdx);

      final (marker, isSajdaAyat) =
          getAyahEndMarkerGlyphCode(surahIdx, surahAyahIdx);
      String text = a.text;
      List<String> fullAyahTextWords =
          widget.getFullAyahText(a.ayahIndex, widget.pageNum).split('\u200c');
      if (isSajdaAyat) {
        text = text.replaceFirst('\u06E9', '');

        for (int i = fullAyahTextWords.length - 1; i >= 0; --i) {
          String w = fullAyahTextWords[i];
          int found = w.indexOf('\u06E9');
          if (found != -1) {
            // for whatever reason, dart is unable to replace '\u06E9' from this word
            // so manually grab substrings of before and after the marker and create
            // a new string
            String b = w.substring(0, found);
            String a = w.substring(found + 1, null);
            w = b + a;
            fullAyahTextWords[i] = w;
            break;
          }
        }
      }

      bool darkMode = Theme.of(context).brightness == Brightness.dark;
      List<String> words = text.split('\u200c'); // zwj
      int i = getFirstWordIndex(fullAyahTextWords, words);

      for (final w in words) {
        int wordIdx = i;
        final tapHandler = TapAndLongPressGestureRecognizer(
            onTap: () => _tapHandler(surahIdx, surahAyahIdx, wordIdx, false),
            onLongPress: () =>
                _tapHandler(surahIdx, surahAyahIdx, wordIdx, true));

        TextStyle? style;

        if (ayahInDb != null) {
          if (ayahInDb.markedWords.contains(wordIdx)) {
            style = _markedWordStyle(darkMode);
          } else if (isMutashabihaAyat) {
            style = _markedMutAyahBGStyle(darkMode);
          } else {
            style = _markedAyahBGStyle(darkMode);
          }
        } else if (isMutashabihaAyat) {
          style = _mutStyle(darkMode);
        }
        // word
        spans.add(TextSpan(recognizer: tapHandler, text: w, style: style));
        // separator
        spans.add(const TextSpan(text: '\u200c'));
        // space
        if (shouldAddSpaces(widget.pageNum, lineIdx)) {
          spans.add(TextSpan(text: ' ', style: style));
        }
        i++;
      }

      if (_shouldDrawAyahEndMarker(a.ayahIndex, lineIdx)) {
        bool hasRukuMarker = a.text.lastIndexOf("\uE022") != -1;
        spans.add(
          TextSpan(
            text: marker,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              backgroundColor: hasRukuMarker
                  ? (darkMode
                      ? Colors.amber.shade700.withAlpha(125)
                      : Colors.amber.shade100)
                  : null,
              fontFamily: "AyahNumber",
              fontSize: 24,
            ),
          ),
        );
      }
    }
    return spans;
  }

  Widget _buildLine(Line line, int lineIdx) {
    return Text.rich(
      TextSpan(children: _buildLineSpans(line, lineIdx)),
      textDirection: TextDirection.rtl,
      style: TextStyle(
        color: Theme.of(context).textTheme.bodyMedium?.color,
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
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 8, right: 8),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              separatorBuilder: (ctx, idx) => const Divider(
                color: Colors.grey,
                height: 1,
              ),
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
          ),
        ),
      ],
    );
  }
}
