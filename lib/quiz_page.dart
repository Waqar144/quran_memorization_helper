import 'package:flutter/material.dart';
import 'ayat.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:math';
import 'para_bounds.dart';
import 'ayat_list_view.dart';

class _QuizAyahQuestion {
  final Ayat questionAyah;
  final Ayat nextAyah;
  const _QuizAyahQuestion(this.questionAyah, this.nextAyah);
}

class QuizPage extends StatefulWidget {
  final List<int> _selectedParas;

  const QuizPage(this._selectedParas, {super.key});

  @override
  State<StatefulWidget> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final ValueNotifier<int> _currentQuestion = ValueNotifier(-1);
  List<_QuizAyahQuestion> quizAyahs = [];
  final ValueNotifier<bool> showNextAyah = ValueNotifier(false);
  final List<Ayat> _allAyahs = [];
  final int _total = 20;
  int _score = 0;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _startReadingAyahsForQuiz();
  }

  void _startReadingAyahsForQuiz() async {
    final stream = _readAyahs();
    final random = Random();
    final Set<int> seenIdxes = {};
    int next(int min, int max) => min + random.nextInt(max - min);

    await for (final List<Ayat> ayahs in stream) {
      _allAyahs.addAll(ayahs);
      // limit to 20 questions for now
      if (quizAyahs.length == _total) break;

      // Add one ayah so that we have a ui while we finish in the bg
      if (quizAyahs.isEmpty) {
        // get randome number in range
        int nextAyah = next(0, _allAyahs.length - 1);
        // add the question
        quizAyahs.add(_QuizAyahQuestion(
          _allAyahs[nextAyah],
          _allAyahs[nextAyah + 1],
        ));
        seenIdxes.add(nextAyah);
        if (_currentQuestion.value == -1) {
          _currentQuestion.value = 0;
        }
      }
    }

    // fill up
    while (quizAyahs.length < _total) {
      int nextAyah = next(0, _allAyahs.length - 1);

      // avoid duplicates
      if (seenIdxes.contains(nextAyah)) continue;
      seenIdxes.add(nextAyah);

      quizAyahs.add(_QuizAyahQuestion(
        _allAyahs[nextAyah],
        _allAyahs[nextAyah + 1],
      ));
    }
  }

  Stream<List<Ayat>> _readAyahs() async* {
    final data = await rootBundle.load("assets/quran.txt");
    final quranText = utf8.decode(data.buffer.asUint8List());
    for (final para in widget._selectedParas) {
      final str = quranText.substring(
          paraByteBounds[para].start, paraByteBounds[para].end);
      final List<String> lines = str.split('\n');
      yield <Ayat>[for (int i = 0; i < lines.length; ++i) Ayat(lines[i])];
    }
  }

  void _onDone() {
    Navigator.of(context).pop();
  }

  void _gotoNextQuestion(int scoreIncrement) {
    _score += scoreIncrement;
    if (_currentQuestion.value + 1 >= _total) {
      setState(() {
        _showResults = true;
      });
      return;
    }
    showNextAyah.value = false;
    _currentQuestion.value++;
  }

  Widget _buildAnswerWidget(int current) {
    return ValueListenableBuilder(
      valueListenable: showNextAyah,
      builder: (context, bool show, _) {
        if (!show) {
          return ElevatedButton(
            child: const Text("Show Next Ayah"),
            onPressed: () {
              showNextAyah.value = true;
            },
          );
        }
        return Column(
          children: [
            AyatListItem(ayah: quizAyahs[current].nextAyah),
            const Text("Were you right?"),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor: MaterialStatePropertyAll(
                          Theme.of(context).colorScheme.errorContainer)),
                  child: const Text("No"),
                  onPressed: () => _gotoNextQuestion(0),
                ),
                ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor:
                          MaterialStatePropertyAll(Colors.green.shade100)),
                  child: const Text("Yes"),
                  onPressed: () => _gotoNextQuestion(1),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget buildResults() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Results"),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: () => _onDone())
        ],
      ),
      body: Center(
        child: Text(
          "Your score is $_score/$_total",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showResults) {
      return buildResults();
    }
    return Scaffold(
      appBar: AppBar(
        title: ValueListenableBuilder(
          valueListenable: _currentQuestion,
          builder: (context, idx, _) {
            return Text("Question ${idx + 1}/$_total");
          },
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: _currentQuestion,
        builder: (context, int current, _) {
          if (quizAyahs.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Text("Recite the next ayah",
                    style: Theme.of(context).textTheme.headlineSmall),
                AyatListItem(ayah: quizAyahs[current].questionAyah),
                const Divider(
                  height: 8,
                ),
                _buildAnswerWidget(current)
              ],
            ),
          );
        },
      ),
    );
  }
}
