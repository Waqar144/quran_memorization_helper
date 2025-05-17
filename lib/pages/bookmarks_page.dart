import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/models/ayat.dart';
import 'package:quran_memorization_helper/models/settings.dart';
import 'package:quran_memorization_helper/quran_data/pages.dart';
import 'package:quran_memorization_helper/quran_data/para_bounds.dart';
import 'package:quran_memorization_helper/quran_data/quran_text.dart';
import 'package:quran_memorization_helper/quran_data/surahs.dart';
import 'package:quran_memorization_helper/utils/utils.dart';

class BookmarksPage extends StatefulWidget {
  final ParaAyatModel model;

  const BookmarksPage({super.key, required this.model});

  @override
  State<StatefulWidget> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  int _toVisiblePage(int page) {
    if (isIndoPak(Settings.instance.mushaf)) {
      return page + 2;
    }
    return page + 1;
  }

  (String, String, String, String) _bookmarkStringify(int bookmark) {
    final mushaf = Settings.instance.mushaf;
    int surah = surahForPage(bookmark, mushaf);
    int para = paraForPage(bookmark, mushaf);
    final surahName = surahDataForIdx(surah, arabic: true).name;
    final paraName = getParaNameForIndex(para);
    final firstAyah = firstAyahOfPage(bookmark, mushaf);
    final firstAyahText =
        firstAyah != null
            ? QuranText.instance.spaceSplittedAyahText(firstAyah)
            : "";

    return (
      "Page ${_toVisiblePage(bookmark)}",
      surahName,
      paraName,
      firstAyahText,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bookmarks")),
      body: ListView.separated(
        padding: EdgeInsets.only(left: 8, right: 8),
        separatorBuilder: (context, _) => const Divider(height: 1),
        itemCount: widget.model.bookmarks.length,
        itemBuilder: (context, index) {
          final bookmarkPage = widget.model.bookmarks[index];
          final (page, surah, para, firstAyahText) = _bookmarkStringify(
            bookmarkPage,
          );
          final style = TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontFamily: getQuranFont(),
            fontSize: 20,
            letterSpacing: 0,
            wordSpacing: 2,
          );

          return ListTile(
            title: Text(page),
            isThreeLine: true,
            subtitle: Column(
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(para, style: style),
                Text("Surah: $surah", style: style.copyWith(fontSize: 18)),
                Text(
                  firstAyahText,
                  textDirection: TextDirection.rtl,
                  softWrap: false,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ],
            ),
            onTap: () {
              Navigator.of(context).pop(bookmarkPage);
            },
          );
        },
      ),
    );
  }
}
