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
  final QuizMode mode;
  const _QuizAyahQuestion(this.questionAyah, this.nextAyah, this.mode);
}

String _questionTextForQuizMode(QuizMode m) {
  if (m == QuizMode.nextAyah) {
    return "Recite the next ayah";
  } else if (m == QuizMode.endAyah) {
    return "Finish the ayah";
  }
  throw "Invalid question type";
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
  final List<_QuizAyahQuestion> _wrongAnswers = [];
  late final int _total;
  int _score = 0;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _total = widget._creationArgs.selectedParas.length > 20
        ? widget._creationArgs.selectedParas.length
        : 20;
    _startReadingAyahsForQuiz();
  }

  @override
  void dispose() {
    showNextAyah.dispose();
    _quizAyahs = [];
    _currentQuestion.dispose();

    super.dispose();
  }

  _QuizAyahQuestion _addQuestion(String ayah, String nextAyah) {
    _QuizAyahQuestion nextAyahQuestion() {
      return _QuizAyahQuestion(Ayat(ayah), Ayat(nextAyah), QuizMode.nextAyah);
    }

    _QuizAyahQuestion endAyahQuestion() {
      List<String> words = ayah.split(' ');
      int replaceStart = min((words.length / 2).ceil(), 6);
      final question =
          "${words.sublist(0, words.length - replaceStart).join(' ')}...";
      return _QuizAyahQuestion(Ayat(question), Ayat(ayah), QuizMode.endAyah);
    }

    if (widget._creationArgs.mode == QuizMode.nextAyah) {
      return nextAyahQuestion();
    } else if (widget._creationArgs.mode == QuizMode.endAyah) {
      return endAyahQuestion();
    } else if (widget._creationArgs.mode == QuizMode.mix) {
      if (_quizAyahs.length % 2 == 0) {
        return nextAyahQuestion();
      } else {
        return endAyahQuestion();
      }
    }
    throw "Unknown quiz mode!";
  }

  void _startReadingAyahsForQuiz() async {
    final stream = _readAyahs();
    await for (final _QuizAyahQuestion question in stream) {
      _quizAyahs.add(question);
      if (_currentQuestion.value == -1) {
        _currentQuestion.value = 0;
      }
    }
  }

  Stream<_QuizAyahQuestion> _readAyahs() async* {
    final random = Random();
    int next(int min, int max) => min + random.nextInt(max - min);
    final selectedParas = widget._creationArgs.selectedParas;
    selectedParas.shuffle(random);

    final data = await rootBundle.load("assets/quran.txt");
    final quranText = utf8.decode(data.buffer.asUint8List());
    final Map<int, List<int>> seenAyahsByPara = {};

    while (_quizAyahs.length < _total) {
      for (final int para in selectedParas) {
        int totalAyahsInPara = paraAyahCount[para];

        // get random number
        int r = next(0, totalAyahsInPara - 1);
        // avoid duplicate questions
        if (!seenAyahsByPara.containsKey(para)) {
          seenAyahsByPara[para] = [];
        }
        while (seenAyahsByPara[para]!.contains(r)) {
          r = next(0, totalAyahsInPara - 1);
        }
        seenAyahsByPara[para]!.add(r);

        // find ayah and next ayah
        ParaBounds bounds = paraByteBounds[para];
        int startNl = bounds.start;
        int nextNl = quranText.indexOf('\n', startNl);
        int count = 0;
        String ayah = "";
        String nextAyah = "";
        while (nextNl < bounds.end) {
          if (r == count) {
            ayah = quranText.substring(startNl, nextNl);
            startNl = nextNl + 1;
            nextNl = quranText.indexOf('\n', startNl);
            nextAyah = quranText.substring(startNl, nextNl);
            break;
          }
          count++;
          startNl = nextNl + 1;
          nextNl = quranText.indexOf('\n', startNl);
        }

        yield _addQuestion(ayah, nextAyah);

        if (_quizAyahs.length >= _total) {
          break;
        }
      }
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
            child: const Text("Show Answer"),
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
          const Divider(),
          Text(
            "Ayahs that you got wrong",
            style: Theme.of(context).textTheme.labelLarge,
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
                    Text(_questionTextForQuizMode(_quizAyahs[current].mode),
                        style: Theme.of(context).textTheme.headlineSmall),
                    AyatListItem(ayah: _quizAyahs[current].questionAyah),
                    const Divider(height: 8),
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
