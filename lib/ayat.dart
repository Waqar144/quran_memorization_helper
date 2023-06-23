import 'package:flutter/foundation.dart';

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
  int _currentPara = 1;
  ValueChanged<int>? _paraChanged;

  set onParaChange(ValueChanged<int> paraChanged) => _paraChanged = paraChanged;

  List<Ayat> get ayahs => _paraAyats[_currentPara] ?? [];

  int get currentPara => _currentPara;

  void setData(Map<int, List<Ayat>> data) {
    _paraAyats = data;
    notifyListeners();
  }

  void setAyahs(List<Ayat> ayahs) {
    _paraAyats[_currentPara] = ayahs;
  }

  void setCurrentPara(int para) {
    if (para == _currentPara) return;
    _currentPara = para;
    _paraChanged?.call(para);
    notifyListeners();
  }

  void removeAyahs(Set<int> indices) {
    if (indices.isEmpty) return;
    List<Ayat> ayahs = _paraAyats[_currentPara] ?? [];
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
