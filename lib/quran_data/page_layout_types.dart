class Line {
  final int ayahIdx;
  final int wordStartInAyahIdx;
  // String text;
  const Line(this.ayahIdx, this.wordStartInAyahIdx);

  @override
  toString() {
    return "Line($ayahIdx, $wordStartInAyahIdx)";
  }
}

class Page {
  final int pageNum;
  final List<Line> lines;
  const Page(this.pageNum, this.lines);

  @override
  toString() {
    return "Page($pageNum, $lines)";
  }
}
