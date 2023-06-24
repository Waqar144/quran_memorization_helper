import 'package:flutter/material.dart';
import 'ayat.dart';

class ImportTextPage extends StatelessWidget {
  final List<Ayat> _ayats = [];
  get ayats => _ayats;
  final TextEditingController _controller = TextEditingController();
  final String _para;

  ImportTextPage(int paraNum, {super.key})
      : _para = "Para ${paraNum.toString()}";

  void _onImport(BuildContext context) {
    if (_controller.text.isEmpty) return;
    String text = _controller.text;
    List<String> lines = text.split("\n");
    for (final String line in lines) {
      if (line.isNotEmpty) _ayats.add(Ayat(line));
    }
    Navigator.pop(context, _ayats);
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
            TextFormField(
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
                height: 1.1,
              ),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
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
