import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/gestures.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:quran_memorization_helper/models/settings.dart';
import 'package:quran_memorization_helper/models/ayat.dart';
import 'package:quran_memorization_helper/quran_data/surahs.dart';
import 'package:quran_memorization_helper/quran_data/ayat.dart';
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

  const ReadQuranWidget(this.model, {super.key});

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

    if (_quranUtf8 == null) {
      final data = await rootBundle.load("assets/quran.txt");
      _quranUtf8 = data.buffer;
    }

    _mutashabihat = await importParaMutashabihas(para - 1, _quranUtf8!);
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

  void _onAyahTapped(
      int surahIdx, int ayahIdx, int wordIdx, int pageNum) async {
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
        List<Mutashabiha> mutashabihat, Ayat? aOrM) {
      List<Widget> widgets = [];

      if (aOrM != null) {
        widgets.add(ListTile(
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete),
              Text("Remove marked word", textAlign: TextAlign.center),
            ],
          ),
          onTap: () {
            widget.model.removeAyats(currentParaIndex, aOrM.ayahIdx, wordIdx);
            Navigator.of(context).pop();
            sendRepainEvent();
          },
        ));
        // close action sheet
      } else {
        widgets.add(ListTile(
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add),
              Text("Mark word", textAlign: TextAlign.center),
            ],
          ),
          onTap: () {
            Ayat ayat = Ayat("", ayahIdx: absoluteAyah, [wordIdx]);
            widget.model.addAyahs([ayat]);
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

    List<Mutashabiha> mutashabihat = _getMutashabihaAyat(ayahIdx, surahIdx);
    Ayat? ayatInDb = _getAyatInDB(ayahIdx, surahIdx);
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
                  children: buildMutashabihaActions(mutashabihat, ayatInDb)),
            ),
          );
        },
      );
    } else {
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
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: doload(),
      builder: (context, snapshot) {
        if (_pages.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverFixedExtentList.builder(
          itemExtent: 785,
          itemCount: _pages.length,
          itemBuilder: (ctx, index) {
            return Container(
              height: 785,
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
                  getAyatInDB: _getAyatInDB,
                  onAyahTapped: _onAyahTapped,
                  isMutashabihaAyat: _isMutashabihaAyat,
                  isAyahFull: _isAyahFull,
                  getFullAyahText: _getFullAyahText,
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
  final Ayat? Function(int ayahIdx, int surahIdx) getAyatInDB;
  final void Function(int surahIdx, int ayahIdx, int wordIdx, int pageIdx)
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

  void _tapHandler(int surahIdx, int ayahIdx, int wordIdx) async {
    widget.onAyahTapped(surahIdx, ayahIdx, wordIdx, widget.pageNum);
  }

  Widget getTwoLinesBismillah(int surahIdx) {
    final style = TextStyle(
      color: Colors.black,
      fontFamily: "Al Mushaf",
      fontSize: Settings.instance.fontSize.toDouble(),
      letterSpacing: 0.0,
      wordSpacing: Settings.instance.wordSpacing.toDouble(),
    );
    SurahData surahData = surahDataForIdx(surahIdx, arabic: true);

    return Column(
      textDirection: TextDirection.rtl,
      children: [
        // surah name and ayah count
        Container(
          height: 46,
          decoration:
              BoxDecoration(border: Border.all(color: Colors.black, width: 1)),
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
            border: Border.all(color: Colors.black, width: 1),
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

    // 30th para ?
    if (widget.pageNum >= 528) {
      if (surahHas2LineHeadress(surahIdx)) {
        return getTwoLinesBismillah(surahIdx);
      }
    } else if (widget._pageLines.length == 15) {
      return getTwoLinesBismillah(surahIdx);
    }

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

  List<TextSpan> _buildLineSpans(Line line, int lineIdx) {
    List<TextSpan> spans = [];
    for (final a in line.lineAyahs) {
      final int surahIdx = surahForAyah(a.ayahIndex);
      final int surahAyahIdx = toSurahAyahOffset(surahIdx, a.ayahIndex);
      final Ayat? ayahInDb = widget.getAyatInDB(surahAyahIdx, surahIdx);
      final bool isMutashabihaAyat =
          widget.isMutashabihaAyat(surahAyahIdx, surahIdx);
      List<String> words = a.text.split('\u200c'); // zwj
      final fullAyahTextWords =
          widget.getFullAyahText(a.ayahIndex, widget.pageNum).split('\u200c');
      int i = fullAyahTextWords.indexOf(words.first);

      for (final w in words) {
        int wordIdx = i;
        if (ayahInDb != null) {
          spans.add(TextSpan(
              text: w,
              recognizer: TapGestureRecognizer()
                ..onTap = () => _tapHandler(surahIdx, surahAyahIdx, wordIdx),
              style: TextStyle(
                inherit: true,
                backgroundColor: Colors.red.shade100,
                color:
                    ayahInDb.markedWords.contains(wordIdx) ? Colors.red : null,
              )));
        } else if (isMutashabihaAyat) {
          spans.add(TextSpan(
              text: w,
              recognizer: TapGestureRecognizer()
                ..onTap = () => _tapHandler(surahIdx, surahAyahIdx, wordIdx),
              style: const TextStyle(inherit: true, color: Colors.indigo)));
        } else {
          spans.add(TextSpan(
              recognizer: TapGestureRecognizer()
                ..onTap = () => _tapHandler(surahIdx, surahAyahIdx, wordIdx),
              text: w));
        }
        spans.add(const TextSpan(text: '\u200c'));
        i++;
      }

      if (_shouldDrawAyahEndMarker(a.ayahIndex, lineIdx)) {
        spans.add(
          TextSpan(
            text: String.fromCharCode(0xF500 + surahAyahIdx),
            style: const TextStyle(
              color: Colors.black,
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
      style: const TextStyle(
        color: Colors.black,
        fontFamily: "Al Mushaf",
        fontSize: 24,
        letterSpacing: 0,
        wordSpacing: 6,
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
