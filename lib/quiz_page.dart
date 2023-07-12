import 'package:flutter/material.dart';
import 'ayat.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:math';
import 'para_bounds.dart';
import 'ayat_list_view.dart';
import 'quiz.dart';

class _QuizAyahQuestion {
  final Ayat questionAyah;
  final Ayat nextAyah;
  const _QuizAyahQuestion(this.questionAyah, this.nextAyah);
}

class QuizPage extends StatefulWidget {
  final QuizCreationArgs _creationArgs;

  const QuizPage(this._creationArgs, {super.key});

  @override
  State<StatefulWidget> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final ValueNotifier<int> _currentQuestion = ValueNotifier(-1);
  List<_QuizAyahQuestion> _quizAyahs = [];
  final ValueNotifier<bool> showNextAyah = ValueNotifier(false);
  List<_QuizAyahQuestion> _wrongAnswers = [];
  final int _total = 20;
  int _score = 0;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _startReadingAyahsForQuiz();
  }

  @override
  void dispose() {
    showNextAyah.dispose();
    _quizAyahs = [];
    _currentQuestion.dispose();

    super.dispose();
  }

  _QuizAyahQuestion _addQuestion(final List<String> allAyahs, int randomIdx) {
    _QuizAyahQuestion nextAyahQuestion(
        final List<String> allAyahs, int randomIdx) {
      return _QuizAyahQuestion(
          Ayat(allAyahs[randomIdx]), Ayat(allAyahs[randomIdx + 1]));
    }

    _QuizAyahQuestion endAyahQuestion(
        final List<String> allAyahs, int randomIdx) {
      final String ayah = allAyahs[randomIdx];
      List<String> words = ayah.split(' ');
      int replaceStart = min((words.length / 2).ceil(), 6);
      final question =
          "${words.sublist(0, words.length - replaceStart).join(' ')}...";
      return _QuizAyahQuestion(Ayat(question), Ayat(ayah));
    }

    if (widget._creationArgs.mode == QuizMode.nextAyah) {
      return nextAyahQuestion(allAyahs, randomIdx);
    } else if (widget._creationArgs.mode == QuizMode.endAyah) {
      return endAyahQuestion(allAyahs, randomIdx);
    } else if (widget._creationArgs.mode == QuizMode.mix) {
      if (_quizAyahs.length % 2 == 0) {
        return nextAyahQuestion(allAyahs, randomIdx);
      } else {
        return endAyahQuestion(allAyahs, randomIdx);
      }
    }
    throw "Unknown quiz mode!";
  }

  void _startReadingAyahsForQuiz() async {
    final stream = _readAyahs();
    final random = Random();
    final Set<int> seenIdxes = {};
    int next(int min, int max) => min + random.nextInt(max - min);
    final List<String> allAyahs = [];

    await for (final List<String> ayahs in stream) {
      allAyahs.addAll(ayahs);
      // limit to 20 questions for now
      if (_quizAyahs.length == _total) break;

      // Add one ayah so that we have a ui while we finish in the bg
      if (_quizAyahs.isEmpty) {
        // get randome number in range
        int nextAyah = next(0, allAyahs.length - 1);
        // add the question
        _quizAyahs.add(_addQuestion(allAyahs, nextAyah));
        seenIdxes.add(nextAyah);
        if (_currentQuestion.value == -1) {
          _currentQuestion.value = 0;
        }
      }
    }

    // fill up
    while (_quizAyahs.length < _total) {
      int nextAyah = next(0, allAyahs.length - 1);
      // avoid duplicates
      if (seenIdxes.contains(nextAyah)) continue;
      seenIdxes.add(nextAyah);
      _quizAyahs.add(_addQuestion(allAyahs, nextAyah));
    }
  }

  Stream<List<String>> _readAyahs() async* {
    final data = await rootBundle.load("assets/quran.txt");
    final quranText = utf8.decode(data.buffer.asUint8List());
    for (final para in widget._creationArgs.selectedParas) {
      final str = quranText.substring(
          paraByteBounds[para].start, paraByteBounds[para].end);
      yield str.split('\n');
    }
  }

  void _onDone() {
    Navigator.of(context).pop();
  }

  void _gotoNextQuestion(int scoreIncrement) {
    _score += scoreIncrement;
    if (scoreIncrement == 0) {
      _wrongAnswers.add(_quizAyahs[_currentQuestion.value]);
    }

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
            AyatListItem(ayah: _quizAyahs[current].nextAyah),
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
      body: Column(
        children: [
          Center(
            child: Text(
              "Your score is $_score/$_total",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Ayahs that you got wrong",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              separatorBuilder: (context, index) {
                if (index % 2 != 0) return const Divider();
                return const SizedBox.shrink();
              },
              itemCount: _wrongAnswers.length * 2,
              itemBuilder: (context, index) {
                final i = (index / 2).floor();
                if (index % 2 == 0) {
                  return AyatListItem(ayah: _wrongAnswers[i].questionAyah);
                }
                return AyatListItem(ayah: _wrongAnswers[i].nextAyah);
              },
            ),
          )
        ],
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
          if (_quizAyahs.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.all(8),
            child: ListView(
              children: [
                Column(
                  children: [
                    Text("Recite the next ayah",
                        style: Theme.of(context).textTheme.headlineSmall),
                    AyatListItem(ayah: _quizAyahs[current].questionAyah),
                    const Divider(
                      height: 8,
                    ),
                    _buildAnswerWidget(current)
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
