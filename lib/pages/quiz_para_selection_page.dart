import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/models/quiz.dart';
import 'package:quran_memorization_helper/models/settings.dart';

class QuizParaSelectionPage extends StatelessWidget {
  final ValueNotifier<List<int>> _selectedParas = ValueNotifier([]);
  final List<String> _quizModes = ["Next Ayah", "Ayah End", "Mix"];
  final ValueNotifier<QuizMode> _quizMode = ValueNotifier(QuizMode.nextAyah);

  QuizParaSelectionPage({super.key});

  void _onDone(BuildContext context) {
    if (_selectedParas.value.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(
      context,
    ).pop(QuizCreationArgs(_selectedParas.value, _quizMode.value));
  }

  @override
  Widget build(BuildContext context) {
    final isIndoPk = isIndoPak(Settings.instance.mushaf);
    return Scaffold(
      appBar: AppBar(
        title:
            isIndoPk
                ? const Text("Select Paras For Quiz")
                : const Text("Select Juz For Quiz"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => _onDone(context),
          ),
        ],
      ),
      body: Column(
        children: [
          ListTile(
            title: const Text("Quiz Mode"),
            trailing: ValueListenableBuilder(
              valueListenable: _quizMode,
              builder: (context, mode, _) {
                return DropdownButton(
                  items: [
                    for (final s in QuizMode.values)
                      DropdownMenuItem(
                        value: s,
                        child: Text(_quizModes[s.index]),
                      ),
                  ],
                  value: mode,
                  onChanged: (QuizMode? s) {
                    if (s != null) {
                      _quizMode.value = s;
                    }
                  },
                );
              },
            ),
          ),
          const Divider(thickness: 2),
          // Para List
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _selectedParas,
              builder: (context, List<int> selection, _) {
                return ListView.separated(
                  separatorBuilder:
                      (BuildContext context, int index) => const Divider(
                        indent: 8,
                        endIndent: 8,
                        color: Colors.grey,
                        height: 2,
                      ),
                  itemCount: 30,
                  itemBuilder: (context, index) {
                    return CheckboxListTile(
                      title:
                          isIndoPk
                              ? Text("Para ${index + 1}")
                              : Text("Juz ${index + 1}"),
                      value: selection.contains(index),
                      onChanged: (bool? v) {
                        if (v == null) return;
                        if (v) {
                          _selectedParas.value = [...selection, index];
                        } else {
                          selection.removeWhere((i) => i == index);
                          _selectedParas.value = [...selection];
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
