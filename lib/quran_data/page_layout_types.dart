class Line {
  final int ayahIdx;
  final int wordStartInAyahIdx;

  const Line(this.ayahIdx, this.wordStartInAyahIdx);

  @override
  String toString() {
    return "Line($ayahIdx, $wordStartInAyahIdx)";
  }
}

class Page {
  final int pageNum;
  final List<Line> lines;
  const Page(this.pageNum, this.lines);

  @override
  String toString() {
    return "Page($pageNum, $lines)";
  }
}
