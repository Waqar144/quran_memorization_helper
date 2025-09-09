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
  bool _selectionMode = false;
  List<bool> _selectionState = [];

  @override
  void initState() {
    _selectionState = List.filled(widget.model.bookmarks.length, false);
    super.initState();
  }

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

  void _onDeletePress() {
    final bookmarks = widget.model.bookmarks;
    List<int> toDelete = [];
    for (final (i, isSelected) in _selectionState.indexed) {
      if (isSelected) {
        toDelete.add(bookmarks[i]);
      }
    }

    if (toDelete.isEmpty) return;

    setState(() {
      // clear selection
      for (int i = 0; i < _selectionState.length; ++i) {
        _selectionState[i] = false;
      }
      widget.model.removeBookmarks(toDelete);
      if (widget.model.bookmarks.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectionMode == false,
      onPopInvokedWithResult: (_, _) {
        if (_selectionMode) {
          setState(() => _selectionMode = false);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Bookmarks"),
          actions: [
            if (_selectionMode)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _onDeletePress,
              ),
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed:
                  widget.model.bookmarks.isEmpty
                      ? null
                      : () {
                        setState(() {
                          if (!_selectionMode) {
                            _selectionMode = true;
                            return;
                          }
                          for (int i = 0; i < _selectionState.length; ++i) {
                            _selectionState[i] = true;
                          }
                        });
                      },
            ),
          ],
        ),
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

            final column = Column(
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
            );
            final title = Text(page);

            if (_selectionMode) {
              return CheckboxListTile(
                title: title,
                subtitle: column,
                isThreeLine: true,
                value: _selectionState[index],
                onChanged: (bool? newVal) {
                  if (newVal == null) return;
                  setState(() {
                    _selectionState[index] = newVal;
                  });
                },
              );
            }

            return ListTile(
              title: title,
              isThreeLine: true,
              subtitle: column,
              onTap: () {
                if (!_selectionMode) {
                  Navigator.of(context).pop(bookmarkPage);
                }
              },
              onLongPress: () {
                setState(() {
                  _selectionMode = true;
                });
              },
            );
          },
        ),
      ),
    );
  }
}
