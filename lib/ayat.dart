import 'package:flutter/foundation.dart';

extension ValueNotifierToggle on ValueNotifier<bool> {
  void toggle() {
    value = !value;
  }
}

class Ayat {
  Ayat(this.text);
  String text = "";
  int count = 0;

  Ayat.fromJson(Map<String, dynamic> json)
      : text = json["text"],
        count = json["count"];

  Map<String, dynamic> toJson() => {"text": text, "count": count};

  @override
  bool operator ==(Object other) {
    return (other is Ayat) && other.text == text;
  }

  @override
  int get hashCode => text.hashCode;
}

class ParaAyatModel extends ChangeNotifier {
  Map<int, List<Ayat>> _paraAyats = {};
  ValueNotifier<int> currentParaNotifier = ValueNotifier<int>(1);

  set onParaChange(VoidCallback cb) => currentParaNotifier.addListener(cb);

  List<Ayat> get ayahs => _paraAyats[currentPara] ?? [];

  int get currentPara => currentParaNotifier.value;

  void setData(Map<int, List<Ayat>> data) {
    _paraAyats = data;
    notifyListeners();
  }

  void setAyahs(List<Ayat> ayahs) {
    _paraAyats[currentPara] = ayahs;
    notifyListeners();
  }

  void setCurrentPara(int para) {
    if (para == currentPara) return;
    currentParaNotifier.value = para;
    notifyListeners();
  }

  void removeAyahs(Set<int> indices) {
    if (indices.isEmpty) return;
    List<Ayat> ayahs = _paraAyats[currentPara] ?? [];
    for (final int index in indices) {
      ayahs.removeAt(index);
    }
    notifyListeners();
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> out = {};
    _paraAyats.forEach((int para, List<Ayat> ayats) {
      out.putIfAbsent(para.toString(), () => ayats);
    });
    return out;
  }
}
