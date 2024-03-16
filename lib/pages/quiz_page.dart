import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:math';
import 'package:quran_memorization_helper/quran_data/para_bounds.dart';
import 'package:quran_memorization_helper/quran_data/ayat.dart';
import 'package:quran_memorization_helper/widgets/ayat_list_item.dart';
import 'package:quran_memorization_helper/models/quiz.dart';

class _QuizAyahQuestion {
  final Ayat questionAyah;
  final Ayat nextAyah;
  final QuizMode mode;
  final int _paraIndex;
  const _QuizAyahQuestion(
      this.questionAyah, this.nextAyah, this.mode, this._paraIndex);

  int get paraNumber => _paraIndex + 1;
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
  final Map<int, List<Ayat>> _ayahsToAddToDB = {};
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

  _QuizAyahQuestion _addQuestion(
      String ayah, String nextAyah, int paraIndex, int ayahIdx) {
    _QuizAyahQuestion nextAyahQuestion() {
      return _QuizAyahQuestion(
          Ayat(ayah, [], ayahIdx: ayahIdx),
          Ayat(nextAyah, [], ayahIdx: ayahIdx + 1),
          QuizMode.nextAyah,
          paraIndex);
    }

    _QuizAyahQuestion endAyahQuestion() {
      List<String> words = ayah.split(' ');
      int replaceStart = min((words.length / 2).ceil(), 6);
      final question =
          "${words.sublist(0, words.length - replaceStart).join(' ')}...";
      return _QuizAyahQuestion(Ayat(question, [], ayahIdx: ayahIdx),
          Ayat(ayah, [], ayahIdx: ayahIdx), QuizMode.endAyah, paraIndex);
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

        // get random number -> this is the ayah number in para
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

        yield _addQuestion(ayah, nextAyah, para, r);

        if (_quizAyahs.length >= _total) {
          break;
        }
      }
    }
  }

  void _onDone() {
    Navigator.of(context).pop(_ayahsToAddToDB);
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
            AyatListItem(
              ayah: _quizAyahs[current].nextAyah,
              showSurahAyahIndex: false,
            ),
            const Text("Were you right?"),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor: MaterialStatePropertyAll(
                          Theme.of(context).colorScheme.errorContainer)),
                  child: Text(
                    "No",
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer),
                  ),
                  onPressed: () => _gotoNextQuestion(0),
                ),
                ElevatedButton(
                  style: const ButtonStyle(
                      backgroundColor: MaterialStatePropertyAll(Colors.green)),
                  child: const Text(
                    "Yes",
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () => _gotoNextQuestion(1),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _onAyahDismiss(DismissDirection dir, int index) {
    if (dir == DismissDirection.startToEnd) return;
    _onAddAyahToDB(index);
    _wrongAnswers.removeAt(index);
    setState(() {});
  }

  void _onAddAyahToDB(int index) {
    assert(index < _wrongAnswers.length);
    final a = _wrongAnswers[index];

    if (a.mode == QuizMode.nextAyah) {
      _ayahsToAddToDB[a.paraNumber] = [
        ...(_ayahsToAddToDB[a.paraNumber] ?? <Ayat>[]),
        a.questionAyah,
        a.nextAyah
      ];
    } else {
      _ayahsToAddToDB[a.paraNumber] = [
        ...(_ayahsToAddToDB[a.paraNumber] ?? <Ayat>[]),
        a.nextAyah
      ];
    }
  }

  void _onAddAllToDB() {
    for (int i = 0; i < _wrongAnswers.length; ++i) {
      _onAddAyahToDB(i);
    }
    _wrongAnswers.clear();
    setState(() {}); // update UI
  }

  Widget buildResults() {
    List<Widget> getWrongAnswersList() {
      if (_wrongAnswers.isEmpty) {
        return [const SizedBox.shrink()];
      }
      return [
        const Divider(),
        const Padding(
          padding: EdgeInsets.only(left: 8, right: 8),
          child: Text("Below is the list of Ayahs that you got wrong. "
              "You can slide an ayah to add it to the respective para "
              "for revising later or you can click the button below to add all the ayahs at once"),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _onAddAllToDB,
          child: const Text("Add All Ayahs to Respective Paras"),
        ),
        ListView.separated(
          separatorBuilder: (context, index) {
            return const Divider();
          },
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: _wrongAnswers.length,
          itemBuilder: (context, index) {
            return Dismissible(
              key: ObjectKey(_wrongAnswers[index].questionAyah),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              onDismissed: (dir) => _onAyahDismiss(dir, index),
              child: Column(
                children: [
                  AyatListItem(
                    ayah: _wrongAnswers[index].questionAyah,
                    showSurahAyahIndex: false,
                  ),
                  AyatListItem(
                    ayah: _wrongAnswers[index].nextAyah,
                    showSurahAyahIndex: false,
                  )
                ],
              ),
            );
          },
        ),
      ];
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Results"),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: () => _onDone())
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: Text(
                "Your score is $_score/$_total",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            ...getWrongAnswersList(),
          ],
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
          if (_quizAyahs.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.all(8),
            child: ListView(
              children: [
                Column(
                  children: [
                    Text(_questionTextForQuizMode(_quizAyahs[current].mode),
                        style: Theme.of(context).textTheme.headlineSmall),
                    AyatListItem(
                      ayah: _quizAyahs[current].questionAyah,
                      showSurahAyahIndex: false,
                    ),
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
