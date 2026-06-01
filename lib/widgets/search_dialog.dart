import 'package:flutter/material.dart';

class SearchDialogResult {
  final String term;
  final bool wholeWord;

  SearchDialogResult({required this.term, required this.wholeWord});
}

class SearchDialog extends StatefulWidget {
  const SearchDialog({super.key});

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  String _searchInput = '';
  bool _matchWholeWord = false;

  void _submit(String value) {
    Navigator.pop(
      context,
      SearchDialogResult(term: value, wholeWord: _matchWholeWord),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Search'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Enter search term...'),
            onChanged: (value) => _searchInput = value,
            onSubmitted: _submit,
          ),
          const SizedBox(height: 8),
          ListTileTheme(
            child: CheckboxListTile(
              title: const Text('Match whole word'),
              value: _matchWholeWord,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (bool? value) {
                setState(() {
                  _matchWholeWord = value ?? false;
                });
              },
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => _submit(_searchInput),
          child: const Text('Search'),
        ),
      ],
    );
  }
}
