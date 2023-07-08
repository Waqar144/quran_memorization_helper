import 'package:flutter/material.dart';
import 'page_constants.dart';

class QuizParaSelectionPage extends StatelessWidget {
  final ValueNotifier<List<int>> _selectedParas = ValueNotifier([]);

  QuizParaSelectionPage({super.key});

  void _onDone(BuildContext context) {
    if (_selectedParas.value.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context)
        .popAndPushNamed(quizPage, arguments: _selectedParas.value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Paras For Quiz"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => _onDone(context),
          )
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: _selectedParas,
        builder: (context, List<int> selection, _) {
          return ListView.separated(
            separatorBuilder: (BuildContext context, int index) =>
                const Divider(
                    indent: 8, endIndent: 8, color: Colors.grey, height: 2),
            itemCount: 30,
            itemBuilder: (context, index) {
              return CheckboxListTile(
                title: Text("Para ${index + 1}"),
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
    );
  }
}
