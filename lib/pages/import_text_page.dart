import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/ayat.dart';
import 'page_constants.dart';

class ImportTextPage extends StatelessWidget {
  final List<Ayat> _ayats = [];
  get ayats => _ayats;
  final TextEditingController _controller = TextEditingController();
  final String _para;
  final int _currentPara;

  ImportTextPage(this._currentPara, {super.key})
      : _para = "Para ${_currentPara.toString()}";

  void _onImport(BuildContext context) {
    if (_controller.text.isEmpty) return;
    String text = _controller.text;
    List<String> lines = text.split("\n");
    for (final String line in lines) {
      if (line.isNotEmpty) _ayats.add(Ayat(line));
    }
    Navigator.pop(context, _ayats);
  }

  void _onSelectAyahs(BuildContext context) async {
    final ret = await Navigator.pushNamed(
      context,
      paraAyahSelectionPage,
      arguments: _currentPara,
    );
    if (ret == null) return;
    List<Ayat> ayahs = ret as List<Ayat>;
    String s = "";
    for (final a in ayahs) {
      s += a.text;
      s += "\n";
    }
    _controller.text = s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Import Ayahs into $_para"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Text("Import newline separated ayats in $_para"),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _onSelectAyahs(context),
              child: const Text("Select from para..."),
            ),
            const SizedBox(height: 8),
            Expanded(
                child: TextFormField(
              controller: _controller,
              autocorrect: false,
              maxLines: null,
              minLines: 10,
              keyboardType: TextInputType.multiline,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontFamily: "Al Mushaf",
                fontSize: 24,
                letterSpacing: 0.0,
                height: 1.5,
                wordSpacing: 1,
              ),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            )),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _onImport(context),
                    child: const Text("Import"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
