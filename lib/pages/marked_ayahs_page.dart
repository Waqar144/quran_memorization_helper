import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/models/ayat.dart';
import 'package:quran_memorization_helper/widgets/ayat_and_mutashabiha_list_view.dart';

class MarkedAyahsPage extends StatefulWidget {
  final ParaAyatModel model;
  final List<AyatOrMutashabiha> ayahAndMutashabihas;
  MarkedAyahsPage(Map<String, dynamic> arguments, {super.key})
      : model = arguments['model'],
        ayahAndMutashabihas = arguments['ayahAndMutashabihas'];

  @override
  State<StatefulWidget> createState() => _MarkedAyahsPageState();
}

class _MarkedAyahsPageState extends State<MarkedAyahsPage> {
  bool _multipleSelectMode = false;

  @override
  void dispose() {
    super.dispose();
    widget.model.resetSelection();
  }

  void _onDeletePress() {
    assert(_multipleSelectMode);
    widget.model.removeSelectedAyahs();
    _onExitMultiSelectMode();
  }

  void _onExitMultiSelectMode() {
    if (_multipleSelectMode) {
      setState(() {
        _multipleSelectMode = false;
        widget.model.resetSelection();
      });
    }
  }

  void _enterMultiselectMode() {
    setState(() {
      _multipleSelectMode = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_multipleSelectMode) {
          _onExitMultiSelectMode();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Marked ayahs for Para ${widget.model.currentPara}"),
          actions: _multipleSelectMode
              ? [
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _onDeletePress,
                  ),
                  IconButton(
                    icon: const Icon(Icons.select_all),
                    onPressed: () => widget.model.selectAll(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _onExitMultiSelectMode,
                  ),
                ]
              : null,
        ),
        body: ListenableBuilder(
          listenable: widget.model,
          builder: (context, _) {
            return AyatAndMutashabihaListView(
              widget.ayahAndMutashabihas,
              selectionMode: _multipleSelectMode,
              onLongPress: _enterMultiselectMode,
            );
          },
        ),
      ),
    );
  }
}
