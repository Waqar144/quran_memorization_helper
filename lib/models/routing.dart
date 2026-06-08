import 'package:quran_memorization_helper/models/ayat.dart';
import 'package:quran_memorization_helper/models/quiz.dart';

class QuizCreationArgs {
  final List<int> selectedParas;
  final QuizMode mode;
  const QuizCreationArgs(this.selectedParas, this.mode);
}

class ParaMutashabihatArgs {
  final ParaAyatModel model;
  final int para;

  ParaMutashabihatArgs(this.model, this.para);
}

class ReadOnlyQuranPageArgs {
  final ParaAyatModel model;
  final int page;
  final List<int> ayahsToHighlight;

  ReadOnlyQuranPageArgs(
    this.model,
    this.page, {
    this.ayahsToHighlight = const [],
  });
}

class QuranSearchPageArgs {
  final ParaAyatModel model;
  final String searchTerm;
  final bool wholeWord;

  QuranSearchPageArgs({
    required this.searchTerm,
    required this.model,
    required this.wholeWord,
  });
}
