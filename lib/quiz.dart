enum QuizMode {
  nextAyah,
  endAyah,
  mix,
}

class QuizCreationArgs {
  final List<int> selectedParas;
  final QuizMode mode;
  const QuizCreationArgs(this.selectedParas, this.mode);
}
