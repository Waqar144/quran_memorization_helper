import 'dart:io';
import 'dart:typed_data';

// This file is used generate the offsets in lib/quran_data/ayah_offsets.dart
void main() {
  File quranFile = File("assets/quran.txt");
  Uint8List quran = quranFile.readAsBytesSync();
  int newLine = 10;

  int start = 0;
  int n = quran.indexOf(newLine);

  List<int> offsets = [];
  offsets.add(start); // first is 0

  while (n != -1) {
    offsets.add(n);
    start = n + 1;
    n = quran.indexOf(newLine, start);
  }
  if (offsets.length != 6237) {
    throw "invalid offsets len: ${offsets.length}";
  }
  print(offsets);
}
