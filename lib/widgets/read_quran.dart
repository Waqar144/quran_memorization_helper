import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:quran_memorization_helper/models/settings.dart';
import 'package:quran_memorization_helper/models/ayat.dart';
import 'package:quran_memorization_helper/quran_data/pages.dart';
import 'package:quran_memorization_helper/quran_data/quran_text.dart';
import 'package:quran_memorization_helper/quran_data/surahs.dart';
import 'package:quran_memorization_helper/quran_data/para_bounds.dart';
import 'package:quran_memorization_helper/quran_data/ayat.dart';
import 'package:quran_memorization_helper/quran_data/rukus.dart';
import 'package:quran_memorization_helper/quran_data/sixteen_line_indopak_layout.dart';
import 'package:quran_memorization_helper/quran_data/fifteen_line_uthmani_layout.dart';
import 'package:quran_memorization_helper/quran_data/fifteen_line_indopak_layout.dart';
import 'package:quran_memorization_helper/quran_data/thirteen_line_indopak_layout.dart';
import 'package:quran_memorization_helper/quran_data/page_layout_types.dart'
    as layout;
import 'package:quran_memorization_helper/utils/utils.dart';
import 'package:quran_memorization_helper/widgets/mutashabiha_ayat_list_item.dart';
import 'package:quran_memorization_helper/widgets/tap_and_longpress_gesture_recognizer.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'dart:math';

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

double _availableHeight(BuildContext context) {
  // top,bottom padding, will include notch and stuff
  final mqPadding = MediaQuery.paddingOf(context);
  final double top = mqPadding.top;
  final double bottom = mqPadding.bottom;

  final appBarHeight =
      56 +
      View.of(context).viewPadding.top / MediaQuery.devicePixelRatioOf(context);
  final padding = top + bottom + appBarHeight;

  // dont go below 700, we will scroll if below
  return max(700, MediaQuery.sizeOf(context).height - (padding));
}

double _heightMultiplier() {
  if (!Settings.instance.reflowMode) return 1.0;

  final fontSize = Settings.instance.fontSize;
  return switch (fontSize) {
    24 => 1.0,
    28 => 1.2,
    30 => 1.4,
    32 => 1.6,
    34 => 1.8,
    36 => 2.0,
    38 => 2.2,
    _ => throw "unsupported font size $fontSize",
  };
}

class Translation {
  /// The filename of translation
  final String fileName;

  /// The translation buffer
  final ByteBuffer transUtf8;

  /// The line offsets into the buffer
  final List<int> transLineOffsets;

  /// Is this translation the builtin one?
  final bool isBundledTranslation;

  bool get isUrdu => isBundledTranslation || fileName.startsWith("ur.");

  Translation({
    required this.fileName,
    required this.transUtf8,
    required this.transLineOffsets,
    required this.isBundledTranslation,
  });
}

class TranslationTile extends StatefulWidget {
  final String translation;
  final bool isUrduTranslation;
  final bool hasNoMutashabihat;
  final int ayahIndex;

  const TranslationTile(
    this.translation,
    this.isUrduTranslation, {
    required this.hasNoMutashabihat,
    required this.ayahIndex,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _TranslationTileState();
}

class _TranslationTileState extends State<TranslationTile> {
  @override
  Widget build(BuildContext context) {
    final children = [
      Text(
        widget.translation.trim(),
        textDirection: widget.isUrduTranslation ? TextDirection.rtl : null,
        style:
            widget.isUrduTranslation
                ? const TextStyle(
                  fontFamily: "Urdu",
                  fontSize: 22,
                  letterSpacing: 0.0,
                  height: 1.8,
                )
                : null,
      ),
    ];

    if (widget.hasNoMutashabihat) {
      return ListTile(
        title: Column(
          children: [...children, const Divider(indent: 10, endIndent: 10)],
        ),
        subtitle: Text(
          QuranText.instance.spaceSplittedAyahText(widget.ayahIndex),
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: getQuranFont(),
            fontSize: 22,
            wordSpacing: 1,
            letterSpacing: 0,
          ),
        ),
      );
    }

    return ExpansionTile(
      title: const Text("Translation"),
      childrenPadding: EdgeInsets.only(left: 8, right: 8),
      children: children,
    );
  }
}

class LongPressActionSheet extends StatefulWidget {
  final Widget? mutashabihaList;
  final Translation translation;

  /// absoluteAyah index of tapped ayah
  final int tappedAyahIdx;

  const LongPressActionSheet({
    super.key,
    required this.mutashabihaList,
    required this.translation,
    required this.tappedAyahIdx,
  });

  @override
  State<StatefulWidget> createState() => _LongPressActionSheetState();
}

class _LongPressActionSheetState extends State<LongPressActionSheet> {
  late PageController _controller;

  @override
  void initState() {
    int currentAyah = widget.tappedAyahIdx;
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
      itemCount: QuranText.instance.ayahCount(),
      controller: _controller,
      itemBuilder: (context, index) {
        final int ayah = index;
        final int s = widget.translation.transLineOffsets[ayah];
        final int e = widget.translation.transLineOffsets[ayah + 1];
        String translation = utf8.decode(
          widget.translation.transUtf8.asUint8List(s, e - s),
        );
        String metadata = surahAyahText(ayah);
        final int surahIdx = surahForAyah(ayah);
        final int surahAyahIdx = toSurahAyahOffset(surahIdx, ayah);

        // if mutashabiha is null, we always show translation
        bool dontShowMutashabih =
            (widget.mutashabihaList == null) ||
            // else if user has swiped, then we expand
            (widget.mutashabihaList != null && widget.tappedAyahIdx != ayah);
        final translationWidget = TranslationTile(
          translation,
          widget.translation.isUrdu,
          ayahIndex: ayah,
          hasNoMutashabihat: dontShowMutashabih,
        );

        final openOnQuranCom = TextButton.icon(
          onPressed: () {
            launchUrl(
              Uri.parse(
                "https://quran.com/${surahIdx + 1}:${surahAyahIdx + 1}",
              ),
            );
          },
          icon: const Icon(Icons.open_in_new),
          label: Text("$metadata on Quran.com"),
        );

        if (widget.tappedAyahIdx == ayah && widget.mutashabihaList != null) {
          return ListView(
            children: [
              openOnQuranCom,
              translationWidget,
              const Divider(),
              widget.mutashabihaList!,
            ],
          );
        }

        return ListView(children: [openOnQuranCom, translationWidget]);
      },
    );
  }
}

class CustomPageViewScrollPhysics extends ClampingScrollPhysics {
  const CustomPageViewScrollPhysics({super.parent});

  @override
  CustomPageViewScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomPageViewScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring =>
      const SpringDescription(mass: 100, stiffness: 100, damping: 1.2);
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

  static Page fromJson(dynamic json) {
    int pageNum = json["pageNum"] as int;
    List<dynamic> lineDatas = json["lines"] as List<dynamic>;
    List<Line> lines = [];
    for (final lineData in lineDatas) {
      final lineArray = lineData as List<dynamic>;
      List<LineAyah> lineAyahs = [];
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
  final VoidCallback verticalScrollResetFn;
  final Function(int) pageChangedCallback;

  const ReadQuranWidget(
    this.model, {
    required this.pageController,
    super.key,
    required this.verticalScrollResetFn,
    required this.pageChangedCallback,
  });

  @override
  State<StatefulWidget> createState() => _ReadQuranWidget();
}

class _ReadQuranWidget extends State<ReadQuranWidget>
    with SingleTickerProviderStateMixin {
  List<Line> lines = [];
  List<layout.Page> _pages = [];
  List<Mutashabiha> _mutashabihat = [];
  Translation? _translation;
  final _repaintNotifier = StreamController<int>.broadcast();

  @override
  void initState() {
    widget.model.addListener(onModelChanged);
    Settings.instance.addListener(clearCachedTranslation);
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   Future.delayed(const Duration(milliseconds: 100), () {
    //     _fwdPgs();
    //   });
    // });
    super.initState();
    WakelockPlus.enable(); // disable auto screen turn off
  }

  /* Test code to scroll through all pages */
  // void _fwdPgs() {
  //   if (widget.pageController.positions.isEmpty) {
  //     Future.delayed(const Duration(milliseconds: 10), () {
  //       _fwdPgs();
  //     });
  //     return;
  //   }
  //
  //   if (widget.pageController.page == null) {
  //     return;
  //   }
  //   if (widget.pageController.page!.toInt() + 1 < _pages.length) {
  //     widget.pageController.jumpToPage(widget.pageController.page!.toInt() + 1);
  //     Future.delayed(const Duration(milliseconds: 30), () {
  //       // print("Next! ${widget.pageController.page!.toInt()} ${_pages.length}");
  //       _fwdPgs();
  //     });
  //   }
  // }

  @override
  void dispose() {
    widget.model.removeListener(onModelChanged);
    Settings.instance.removeListener(clearCachedTranslation);
    super.dispose();
    WakelockPlus.disable();
  }

  void clearCachedTranslation() {
    // rebuild as reflow mode or other setting might have changed
    setState(() {
      _translation = null;
    });
  }

  void onModelChanged() {
    _repaintNotifier.add(0);
  }

  List<layout.Page> _getPageLayoutList() {
    return switch (Settings.instance.mushaf) {
      Mushaf.Indopak16Line => pages16Indopak,
      Mushaf.Uthmani15Line => pages15Uthmani,
      Mushaf.Indopak15Line => pages15Indopak,
      Mushaf.Indopak13Line => pages13Indopak,
    };
  }

  Future<List<layout.Page>> doload() async {
    // we lazy load the mutashabiha ayat text
    _pages = _getPageLayoutList();
    _mutashabihat = await importAllMutashabihat();
    return _pages;
  }

  bool _isMutashabihaAyat(int surahAyahIdx, int surahIdx) {
    // _mutashabihat is sorted
    final it = _mutashabihat
        .skipWhile((m) => m.src.surahIdx < surahIdx)
        .takeWhile(
          (m) =>
              m.src.surahIdx == surahIdx &&
              m.src.surahAyahIndexes.first <= surahAyahIdx,
        );
    for (final m in it) {
      if (m.src.surahAyahIndexes.contains(surahAyahIdx)) {
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

  Ayat? _getAyatInDB(int ayahIdx) {
    return widget.model.getAyahInDB(ayahIdx);
  }

  void _onAyahLongPressed(int ayahIdx) async {
    int surahIdx = surahForAyah(ayahIdx);
    int surahAyah = toSurahAyahOffset(surahIdx, ayahIdx);
    List<Mutashabiha> mutashabihat = _getMutashabihaAyat(surahAyah, surahIdx);

    if (_translation == null) {
      ByteBuffer transUtf8;
      final isBundledTranslation = Settings.instance.translationFile.isEmpty;
      if (isBundledTranslation) {
        transUtf8 = (await rootBundle.load("assets/ur.jalandhry.txt")).buffer;
      } else {
        final data = File(Settings.instance.translationFile).readAsBytesSync();
        transUtf8 = data.buffer;
      }

      List<int> transLineOffsets = [];
      transLineOffsets.add(0);
      int start = 0;
      final utf = transUtf8.asUint8List();
      int next = utf.indexOf(10);
      while (next != -1) {
        transLineOffsets.add(next);

        start = next + 1;
        next = utf.indexOf(10, start);
      }

      _translation = Translation(
        fileName: Settings.instance.translationFile,
        transUtf8: transUtf8,
        transLineOffsets: transLineOffsets,
        isBundledTranslation: isBundledTranslation,
      );
    }

    for (int i = 0; i < mutashabihat.length; ++i) {
      mutashabihat[i].loadText();
    }

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
      scrollControlDisabledMaxHeightRatio: 0.7,
      builder: (context) {
        return SizedBox(
          width: MediaQuery.sizeOf(context).width,
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: LongPressActionSheet(
              mutashabihaList: mutashabihaWidget,
              translation: _translation!,
              tappedAyahIdx: ayahIdx,
            ),
          ),
        );
      },
    );
  }

  void _onAyahTapped(int ayahIdx, int wordIdx, bool longPress) async {
    bool tapToShowBottomSheet = Settings.instance.tapToShowTranslation;
    if ((longPress && !tapToShowBottomSheet) ||
        (!longPress && tapToShowBottomSheet)) {
      _onAyahLongPressed(ayahIdx);
      return;
    }

    Ayat? ayatInDb = _getAyatInDB(ayahIdx);
    // otherwise we add/remove ayah
    if (ayatInDb != null && ayatInDb.markedWords.contains(wordIdx)) {
      // remove
      widget.model.removeMarkedWordInAyat(ayahIdx, wordIdx);
    } else {
      // add
      Ayat ayat = Ayat("", [wordIdx], ayahIdx: ayahIdx);
      widget.model.addAyahs([ayat]);
    }
  }

  @override
  Widget build(BuildContext context) {
    // set to true when swiping to load next para
    return FutureBuilder(
      future: doload(),
      builder: (context, snapshot) {
        if (_pages.isEmpty ||
            snapshot.connectionState != ConnectionState.done) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverToBoxAdapter(
          child: SizedBox(
            height: _availableHeight(context) * _heightMultiplier(),
            child: NotificationListener<OverscrollNotification>(
              onNotification: (noti) {
                if (noti.depth == 0) {
                  int dir = noti.overscroll >= 0 ? 1 : -1;
                  bool lastpage = dir < 0;
                  if (lastpage) {
                    widget.pageController.jumpToPage(_pages.length - 1);
                  } else {
                    widget.pageController.jumpToPage(0);
                  }
                }
                return false;
              },
              child: PageView.builder(
                onPageChanged: (newPage) {
                  // reset vertical scroll only if in reflow mode
                  // because otherwise its annoying as we usually
                  // have vertical scroll of 1 line and the user
                  // keeps scrolling that 1 line again and again
                  if (Settings.instance.reflowMode) {
                    widget.verticalScrollResetFn();
                  }
                  widget.pageChangedCallback(newPage);
                },
                controller: widget.pageController,
                reverse: true,
                itemCount: _pages.length,
                scrollBehavior:
                    const ScrollBehavior()..copyWith(overscroll: false),
                physics: const CustomPageViewScrollPhysics(),
                itemBuilder: (ctx, index) {
                  final page = _pages[index];
                  List<Line> pageLines = [];

                  for (int i = 0; i < page.lines.length; ++i) {
                    final l = page.lines[i];
                    final ayah = l.ayahIdx;
                    final start = l.wordStartInAyahIdx;
                    List<LineAyah> lineAyahs = [];

                    if (ayah < 0) {
                      pageLines.add(
                        Line([LineAyah(start == -999 ? start : start - 1, "")]),
                      );
                      continue;
                    }

                    int? nextAyah;
                    int? nextAyahStart;
                    if (i + 1 < page.lines.length) {
                      if (page.lines[i + 1].ayahIdx >= 0) {
                        final nextLine = page.lines[i + 1];
                        nextAyah = nextLine.ayahIdx;
                        nextAyahStart = nextLine.wordStartInAyahIdx;
                      } else {
                        // find next valid ayah
                        for (int j = i + 1; j < page.lines.length; ++j) {
                          if (page.lines[j].ayahIdx >= 0) {
                            nextAyah = page.lines[j].ayahIdx;
                            nextAyahStart = 0;
                            break;
                          }
                        }
                      }
                    } else if (index + 1 < _pages.length) {
                      final nextPage = _pages[index + 1];
                      if (nextPage.lines.first.ayahIdx >= 0) {
                        final nextPageFirstLine = nextPage.lines.first;
                        nextAyah = nextPageFirstLine.ayahIdx;
                        nextAyahStart = nextPageFirstLine.wordStartInAyahIdx;
                      } else {
                        // find next valid ayah
                        for (int j = 0; j < nextPage.lines.length; ++j) {
                          if (nextPage.lines[j].ayahIdx >= 0) {
                            nextAyah = nextPage.lines[j].ayahIdx;
                            nextAyahStart = 0;
                            break;
                          }
                        }
                      }
                    }

                    final d = QuranText.instance.ayahsForRanges(
                      ayah,
                      start,
                      nextAyah,
                      nextAyahStart,
                    );
                    for (final line in d) {
                      lineAyahs.add(LineAyah(line.$1, line.$2));
                    }
                    pageLines.add(Line(lineAyahs));
                  }

                  return ExcludeSemantics(
                    child: PageWidget(
                      index,
                      _pages[index].pageNum,
                      pageLines,
                      getAyatInDB: _getAyatInDB,
                      onAyahTapped: _onAyahTapped,
                      isMutashabihaAyat: _isMutashabihaAyat,
                      repaintStream: _repaintNotifier.stream,
                      isBookmarked:
                          () => widget.model.bookmarks.contains(index),
                      onToggleBookmark: () {
                        if (widget.model.bookmarks.contains(index)) {
                          widget.model.removeBookmark(index);
                        } else {
                          widget.model.addBookmark(index);
                        }
                      },
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
  final int pageIndex;
  final int pageNumber;
  final List<Line> _pageLines;
  final bool Function(int ayahIdx, int surahIdx) isMutashabihaAyat;
  final Ayat? Function(int ayahIdx) getAyatInDB;
  final void Function(int ayahIdx, int wordIdx, bool longPress) onAyahTapped;
  final Stream<int> repaintStream;
  final bool Function() isBookmarked;
  final void Function() onToggleBookmark;

  const PageWidget(
    this.pageIndex,
    this.pageNumber,
    this._pageLines, {
    required this.isMutashabihaAyat,
    required this.getAyatInDB,
    required this.onAyahTapped,
    required this.repaintStream,
    required this.isBookmarked,
    required this.onToggleBookmark,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _PageWidgetState();
}

class _PageWidgetState extends State<PageWidget> {
  StreamSubscription<int>? _subscription;

  // These variables are used to optimize ayah portion lookup in the
  // full ayah text
  int _lastAyahIdx = -1;
  int _lastRenderedWordIdx = -1;

  @override
  void initState() {
    super.initState();
    _subscription = widget.repaintStream.listen(_triggerRepaint);
  }

  void _triggerRepaint(v) {
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
  }

  Widget _getBism(TextStyle style, double rowHeight) {
    return Container(
      height: rowHeight,
      width: MediaQuery.sizeOf(context).width,
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.4),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Text(
        String.fromCharCode(0xFDFD),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: style.copyWith(
          fontFamily: "Bismillah",
          fontSize: Theme.of(context).textTheme.headlineLarge?.fontSize,
        ),
      ),
    );
  }

  Widget _getSurahHeaddress(
    int surahIdx,
    TextStyle style,
    double rowHeight, {
    bool includeBismillah = false,
  }) {
    SurahData surahData = surahDataForIdx(surahIdx, arabic: true);
    final isSurahTawba = surahIdx == 8;
    return Container(
      padding: const EdgeInsets.only(left: 2, right: 2),
      height: rowHeight,
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.4),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Row(
        children: [
          Text(
            " ${toArabicNumber(surahData.ayahCount)}",
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: style.copyWith(fontFamily: "Urdu"),
          ),
          Text(
            "آياتها",
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: style.copyWith(fontFamily: "Al Mushaf"),
          ),
          if (includeBismillah && !isSurahTawba) const Spacer(),
          if (includeBismillah && !isSurahTawba)
            Text(
              isSurahTawba ? "-" : String.fromCharCode(0xFDFD),
              textDirection: TextDirection.rtl,
              style: style.copyWith(
                fontFamily: "Bismillah",
                fontSize: Theme.of(context).textTheme.headlineLarge?.fontSize,
              ),
            ),
          const Spacer(),
          Text(
            String.fromCharCodes([surahGlyphCode(surahIdx), 0xe903]),
            textDirection: TextDirection.rtl,
            style: style.copyWith(fontFamily: "SurahNames"),
          ),
        ],
      ),
    );
  }

  void _onRukuTapped(int ayahIndex) async {
    final rukuData = getRukuData(ayahIndex)!;
    await showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text("Ruku"),
          children: [
            ListTile(title: Text("Para Ruku No: ${rukuData.paraRuku + 1}")),
            ListTile(title: Text("Surah Ruku No: ${rukuData.surahRuku + 1}")),
          ],
        );
      },
    );
  }

  // Finds the correct position of the first word of the line
  // in the full ayah text
  static int getFirstWordIndex(
    String fullAyah,
    String currentLine,
    int startSearchAt,
  ) {
    // Find the position of currentLine in full Ayah
    int match = fullAyah.indexOf(currentLine, startSearchAt);
    if (match == -1) {
      throw "Didn't find anything, bug!\n$currentLine\n$fullAyah";
    }

    // Find the index of first word
    int s = fullAyah.indexOf("\u200c");
    int wordIndex = 0;
    while (true) {
      if (s >= match) break;
      s = fullAyah.indexOf("\u200c", s + 1);
      wordIndex++;
    }
    return wordIndex;
  }

  List<TextSpan> _buildLineSpans(
    Line line,
    int lineIdx,
    List<(int ayahIndex, int, int, Ayat?, bool, String)> ayahData,
    ThemeData themeData, {
    required bool reflowMode,
  }) {
    List<TextSpan> spans = [];
    final isIndoPk = isIndoPak(Settings.instance.mushaf);
    bool darkMode = themeData.brightness == Brightness.dark;

    for (final a in line.lineAyahs) {
      final (
        _,
        int surahIdx,
        int surahAyahIdx,
        Ayat? ayahInDb,
        bool isMutashabihaAyat,
        String fullAyahText,
      ) = ayahData.firstWhere(
        (data) {
          return data.$1 == a.ayahIndex;
        },
        orElse: () {
          throw "Unexpected unable to find the index for given ayahIdx: ${a.ayahIndex}";
        },
      );

      String text = a.text;

      int startSearchAt = 0;
      if (_lastAyahIdx == a.ayahIndex) {
        // start search in the full ayah text after the
        // last rendered word
        startSearchAt = _lastRenderedWordIdx;
      }
      _lastAyahIdx = a.ayahIndex;

      List<String> words = text.split('\u200c'); // zwj
      int i = getFirstWordIndex(fullAyahText, text, startSearchAt);

      int lastWordInLineIndex = words.length - 1;
      if (words.last.isEmpty) {
        lastWordInLineIndex -= 1;
      }

      for (final (idx, w) in words.indexed) {
        if (w.isEmpty) {
          i++;
          continue;
        }

        int wordIdx = i;
        final tapHandler = TapAndLongPressGestureRecognizer(
          onTap: () => widget.onAyahTapped(a.ayahIndex, wordIdx, false),
          onLongPress: () => widget.onAyahTapped(a.ayahIndex, wordIdx, true),
        );

        TextStyle? style;

        if (w.contains("\u06dd")) {
          final ruku = isIndoPk ? getRukuData(a.ayahIndex) : null;
          final hasRukuMarker = ruku != null;
          spans.add(
            TextSpan(
              text: hasRukuMarker ? " $w" : w,
              recognizer:
                  hasRukuMarker
                      ? (TapGestureRecognizer()
                        ..onTap = () => _onRukuTapped(a.ayahIndex))
                      : null,
              style: TextStyle(
                inherit: true,
                color:
                    isIndoPk
                        ? themeData.textTheme.bodyMedium?.color
                        : Colors.black,
                backgroundColor:
                    hasRukuMarker
                        ? (darkMode
                            ? Colors.amber.shade700.withAlpha(125)
                            : Colors.amber.shade100)
                        : null,
              ),
            ),
          );
          i++;
          continue;
        }

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
        // space
        if (idx != lastWordInLineIndex) {
          spans.add(TextSpan(text: ' ', style: style));
        }

        i++;
      }

      _lastRenderedWordIdx = i;
    }
    return spans;
  }

  TextStyle _getQuranTextStyle(double fontSize, {double wordSpacing = 1.0}) {
    return TextStyle(
      color: Theme.of(context).textTheme.bodyMedium?.color,
      fontFamily: getQuranFont(),
      fontSize: fontSize,
      letterSpacing: 0,
      wordSpacing: wordSpacing,
    );
  }

  double _getWordSpacing(
    int lineIdx,
    List<TextSpan> spans,
    double width,
    TextStyle style,
    Mushaf mushaf,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(children: spans, style: style),
      textDirection: TextDirection.rtl,
      maxLines: 1,
    );
    textPainter.layout();
    var diffW = (min(width, 700) - textPainter.width);
    textPainter.dispose();

    if (diffW > 10) {
      if (isSurahLastLine(widget.pageIndex, lineIdx, mushaf) &&
          diffW >= min(width, 700) / 3) {
        return 2;
      }
      int spaces = 0;
      for (final s in spans) {
        if (s.text == ' ') spaces++;
      }
      return (spaces > 0 ? diffW / (spaces) : 1).roundToDouble();
    } else if (diffW < -10) {
      if (diffW <= 20) {
        return -1;
      }
      return -4;
    } else {
      return 2;
    }
  }

  Widget _buildLine(
    Line line,
    int lineIdx,
    double rowHeight,
    List<(int, int, int, Ayat?, bool, String)> ayahData,
    double fontSize,
    double width,
    TextStyle style,
    ThemeData themeData,
    Mushaf mushaf,
  ) {
    final spans = _buildLineSpans(
      line,
      lineIdx,
      ayahData,
      themeData,
      reflowMode: false,
    );
    // dont try to space first two pages
    int firstTwo = Settings.instance.mushaf == Mushaf.Indopak16Line ? 3 : 2;
    final wordSpacing =
        widget.pageNumber < firstTwo
            ? 1.0
            : _getWordSpacing(lineIdx, spans, width, style, mushaf);

    return Text.rich(
      TextSpan(children: spans),
      textDirection: TextDirection.rtl,
      softWrap: false,
      maxLines: 1,
      // min(26, (rowHeight / 1.8).floorToDouble()),
      style: style.copyWith(wordSpacing: wordSpacing),
    );
  }

  int _getLastLineAyah() {
    for (final line in widget._pageLines.reversed) {
      for (final a in line.lineAyahs) {
        if (a.ayahIndex >= 0) {
          return a.ayahIndex;
        }
      }
    }
    throw "Did not find any ayahs!!";
  }

  Widget _pageTopBorder() {
    return SizedBox(
      height: 24,
      child: Row(
        children: [
          Text(
            surahDataForIdx(
              surahForAyah(_getLastLineAyah()),
              arabic: true,
            ).name,
            style: TextStyle(
              fontSize: 16,
              fontFamily: getQuranFont(),
              letterSpacing: 0,
            ),
          ),
          Expanded(
            child:
                widget.isBookmarked()
                    ? const Icon(
                      Icons.bookmark_added,
                      size: 24,
                      color: Colors.orange,
                    )
                    : Container(),
          ),
          InkWell(
            onTap: widget.onToggleBookmark,
            child: Text(
              (widget.pageNumber + 1).toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const Spacer(),
          Text(
            getParaNameForIndex(
              paraForPage(widget.pageIndex, Settings.instance.mushaf),
            ),
            style: TextStyle(
              fontSize: 16,
              fontFamily: getQuranFont(),
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSurahHeaddress(int lineIdx, Line line, double rowHeight) {
    List<Widget> widgets = [];
    final style = TextStyle(
      color: Theme.of(context).textTheme.bodyMedium?.color,
      fontFamily: getQuranFont(),
      fontSize: Theme.of(context).textTheme.titleLarge?.fontSize,
      letterSpacing: 0.0,
      wordSpacing: 0,
    );
    final isIndoPk = isIndoPak(Settings.instance.mushaf);
    if (line.lineAyahs.first.ayahIndex == -999) {
      widgets.add(_getBism(style, rowHeight));
    } else {
      bool drawBismillah =
          isIndoPk &&
          lineIdx + 1 < widget._pageLines.length &&
          widget._pageLines[lineIdx + 1].lineAyahs.first.ayahIndex >= 0;
      widgets.add(
        _getSurahHeaddress(
          -(line.lineAyahs.first.ayahIndex + 1),
          style,
          rowHeight,
          includeBismillah: drawBismillah,
        ),
      );
    }
    return widgets;
  }

  List<Widget> _reflowModeText(
    double rowHeight,
    List<(int, int, int, Ayat?, bool, String)> ayahData,
    ThemeData themeData,
  ) {
    List<Widget> widgets = [];
    List<TextSpan> spans = [];
    for (final (lineIdx, line) in widget._pageLines.indexed) {
      if (line.lineAyahs.first.ayahIndex < 0) {
        if (spans.isNotEmpty) {
          widgets.add(
            Text.rich(
              TextSpan(children: spans),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              softWrap: true,
              style: _getQuranTextStyle(Settings.instance.fontSize.toDouble()),
            ),
          );
          spans = [];
        }

        widgets.addAll(_buildSurahHeaddress(lineIdx, line, rowHeight));
        continue;
      }

      spans.addAll(
        _buildLineSpans(line, lineIdx, ayahData, themeData, reflowMode: true),
      );
    }
    if (spans.isNotEmpty) {
      widgets.add(
        Text.rich(
          TextSpan(children: spans),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          softWrap: true,
          style: _getQuranTextStyle(Settings.instance.fontSize.toDouble()),
        ),
      );
      spans = [];
    }
    return widgets;
  }

  static double _textFontSize() {
    if (isBigScreen()) {
      if (Settings.instance.mushaf == Mushaf.Uthmani15Line) {
        return 36.0;
      }
      return 34.0;
    } else if (Settings.instance.mushaf == Mushaf.Uthmani15Line) {
      return 30.0;
    } else {
      return 26.0;
    }
  }

  List<Widget> _pageLines(double rowHeight, double rowWidth) {
    int lastAyah = -1;
    List<(int, int, int, Ayat?, bool, String)> ayahData = [];
    ayahData.length = 0;
    final colorMutashabihat = Settings.instance.colorMutashabihat;

    for (final l in widget._pageLines) {
      if (l.lineAyahs.first.ayahIndex < 0) {
        continue; // bismillah
      }
      for (final a in l.lineAyahs) {
        if (lastAyah == a.ayahIndex) {
          continue;
        } else {
          lastAyah = a.ayahIndex;
          final int surahIdx = surahForAyah(a.ayahIndex);
          final int surahAyahIdx = toSurahAyahOffset(surahIdx, a.ayahIndex);
          final Ayat? ayahInDb = widget.getAyatInDB(a.ayahIndex);
          final text = QuranText.instance.ayahText(a.ayahIndex);
          final bool isMutashabihaAyat =
              colorMutashabihat
                  ? widget.isMutashabihaAyat(surahAyahIdx, surahIdx)
                  : false;

          ayahData.add((
            a.ayahIndex,
            surahIdx,
            surahAyahIdx,
            ayahInDb,
            isMutashabihaAyat,
            text,
          ));
        }
      }
    }

    final themeData = Theme.of(context);

    // reset cached values before page renders
    _lastAyahIdx = -1;
    _lastRenderedWordIdx = -1;

    if (Settings.instance.reflowMode) {
      return _reflowModeText(rowHeight, ayahData, themeData);
    }

    List<Widget> widgets = [];
    const divider = Divider(color: Colors.grey, height: 1);
    final bigScreen = isBigScreen();
    final defaultTextStyle = _getQuranTextStyle(_textFontSize());

    final mushaf = Settings.instance.mushaf;
    final isIndoPk = isIndoPak(mushaf);
    final fontSize = _textFontSize();
    final boxFit = bigScreen ? BoxFit.contain : BoxFit.scaleDown;
    final leftRightBorder = BoxDecoration(
      border: Border.symmetric(
        vertical: BorderSide(color: themeData.dividerColor, width: 1),
      ),
    );

    for (final (idx, l) in widget._pageLines.indexed) {
      if (l.lineAyahs.first.ayahIndex < 0) {
        widgets.addAll(_buildSurahHeaddress(idx, l, rowHeight));
        continue;
      }

      // 15 line uthmani is not separated by divider
      if (isIndoPk) widgets.add(divider);
      // except first line, as its the top border of page
      if (!isIndoPk && idx == 0) widgets.add(divider);

      widgets.add(
        Container(
          height: rowHeight,
          width: double.infinity,
          padding: const EdgeInsets.only(left: 4, right: 4),
          decoration: leftRightBorder,
          child: FittedBox(
            fit: boxFit,
            child: _buildLine(
              l,
              idx,
              rowHeight,
              ayahData,
              fontSize,
              rowWidth,
              defaultTextStyle,
              themeData,
              mushaf,
            ),
          ),
        ),
      );
    }
    widgets.add(divider);

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final numPageLines = switch (Settings.instance.mushaf) {
      Mushaf.Indopak16Line => 16,
      Mushaf.Indopak15Line || Mushaf.Uthmani15Line => 15,
      Mushaf.Indopak13Line => 13,
    };

    final double height =
        _availableHeight(context) -
        ( /*divider between lines(1px)*/ 24 +
            /*topborder=*/ 24);
    final double rowHeight = max((height / numPageLines).floorToDouble(), 38.0);
    final double rowWidth = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4),
      child: Column(
        children: [
          // Top border
          _pageTopBorder(),
          // Divider
          if (Settings.instance.reflowMode)
            const Divider(color: Colors.grey, height: 1),
          // The actual page text
          ..._pageLines(rowHeight, rowWidth),
        ],
      ),
    );
  }
}
