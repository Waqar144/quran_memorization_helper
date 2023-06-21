class Ayat {
  Ayat(this.text);
  String text = "";
  int count = 0;

  Ayat.fromJson(Map<String, dynamic> json)
      : text = json["text"],
        count = json["count"];

  Map<String, dynamic> toJson() => {"text": text, "count": count};
}
