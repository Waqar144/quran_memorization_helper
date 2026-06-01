import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:quran_memorization_helper/models/routing.dart';
import 'package:quran_memorization_helper/models/settings.dart';
import 'package:quran_memorization_helper/pages/page_constants.dart';
import 'package:quran_memorization_helper/quran_data/para_bounds.dart';
import 'package:quran_memorization_helper/quran_data/quran_text.dart';
import 'package:quran_memorization_helper/quran_data/ayat.dart';
import 'package:quran_memorization_helper/widgets/ayat_list_item.dart';

class _SearchMatch {
  final int ayahIndex;
  final int wordIndex;
  const _SearchMatch(this.ayahIndex, this.wordIndex);
}

class QuranSearchPage extends StatefulWidget {
  final QuranSearchPageArgs args;

  const QuranSearchPage(this.args, {super.key});

  @override
  State<QuranSearchPage> createState() => _QuranSearchPageState();
}

class _QuranSearchPageState extends State<QuranSearchPage> {
  String searchTerm = "";
  late Future<List<_SearchMatch>> _searchFuture;
  Map<int, int> ayahWordMatchCache = {};

  String normalizeSearchTerm(String input) {
    const Map<String, String> charNormalizationMap = {
      /* ltr */ 'ک': 'ك', // Urdu Keheh (U+06A9) -> Arabic Kaf (U+0643)
      /* ltr */ 'ی': 'ي', // Urdu Yeh (U+06CC)   -> Arabic Yeh (U+064A)
      /* ltr */ 'ے': 'ي', // Urdu Bari Yeh (U+06D2) -> Arabic Yeh (U+064A)
      /* ltr */ 'ہ': 'ه', // Urdu Doachashmee/Heh -> Arabic Heh (U+0647)
      /* ltr */ 'ھ': 'ه',
      /*ltr */ 'ۃ': 'ة',
    };

    if (input.isEmpty) return input;

    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      buffer.write(charNormalizationMap[char] ?? char);
    }

    return buffer.toString();
  }

  Future<List<_SearchMatch>> _loadAndSearch() async {
    final String data = await rootBundle.loadString(
      'assets/quran_simple.txt',
      cache: false,
    );
    final quranLines = data.split('\n');

    if (searchTerm.isEmpty) return [];

    final bool wholeWord = widget.args.wholeWord;

    final ayahCount = QuranText.instance.ayahCount();
    final List<_SearchMatch> matches = [];
    for (int i = 0; i < ayahCount; i++) {
      final ayahText = quranLines[i];
      int startSearchPos = 0;

      while (true) {
        final matchPos = ayahText.indexOf(searchTerm, startSearchPos);
        if (matchPos == -1) break;

        // bool debug = ayahText.contains("");

        if (wholeWord && matchPos > 0 && ayahText[matchPos - 1] != '\u200c') {
          break;
        }
        // if (debug) {
        //   print("Passed 1");
        // }

        if (wholeWord &&
            matchPos + searchTerm.length < ayahText.length &&
            ayahText[matchPos + searchTerm.length] != '\u200c') {
          break;
        }

        // if (debug) {
        //   print(
        //     "Passed 2 ${ayahText.length < matchPos + searchTerm.length} --- ${ayahText.length} ---- ${matchPos} --- ${searchTerm.length}",
        //   );
        // }

        // Count spaces before matchPos to find the 0-based word index
        int currentWordIndex = 0;
        int spacePos = 0;
        while (true) {
          spacePos = ayahText.indexOf('\u200c', spacePos);
          if (spacePos == -1 || spacePos >= matchPos) break;
          currentWordIndex++;
          spacePos++; // Move past the space
        }

        matches.add(_SearchMatch(i, currentWordIndex));

        startSearchPos = matchPos + searchTerm.length;
      }
    }
    return matches;
  }

  @override
  void initState() {
    super.initState();
    searchTerm = normalizeSearchTerm(widget.args.searchTerm);
    _searchFuture = _loadAndSearch();
  }

  void onGotoResult(int ayahIndex) {
    final page = getPageForAyah(ayahIndex, Settings.instance.mushaf);
    Navigator.of(context).pushNamed(
      goToPageModal,
      arguments: ReadOnlyQuranPageArgs(widget.args.model, page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomAppBar(
        padding: EdgeInsets.zero,
        height: kToolbarHeight,
        child: AppBar(
          title: const Text("Search"),
          actions: [
            // IconButton(
            //   icon: const Icon(Icons.refresh),
            //   onPressed: () {
            //     print("Resetting");
            //     setState(() {
            //       _searchFuture = _loadAndSearch();
            //     });
            //   },
            // ),
          ],
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<_SearchMatch>>(
          future: _searchFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final results = snapshot.data ?? [];

            if (results.isEmpty) {
              return const Center(child: Text('No matches found'));
            }

            return ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final result = results[index];
                final ayah = Ayat(
                  QuranText.instance.ayahText(result.ayahIndex),
                  [result.wordIndex],
                  ayahIdx: result.ayahIndex,
                );

                return Card(
                  child: AyatListItem(
                    ayah: ayah,
                    showSurahAyahIndex: true,
                    onGoto: () => onGotoResult(result.ayahIndex),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
