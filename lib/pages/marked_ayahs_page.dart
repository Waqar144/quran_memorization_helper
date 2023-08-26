import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/models/ayat.dart';
import 'package:quran_memorization_helper/widgets/ayat_and_mutashabiha_list_view.dart';

class MarkedAyahsPage extends StatefulWidget {
  final ParaAyatModel model;
  const MarkedAyahsPage(this.model, {super.key});

  @override
  State<StatefulWidget> createState() => _MarkedAyahsPageState();
}

class _MarkedAyahsPageState extends State<MarkedAyahsPage> {
  final ValueNotifier<bool> _multipleSelectMode = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _multipleSelectMode.addListener(widget.model.resetSelection);
  }

  @override
  void dispose() {
    super.dispose();
    _multipleSelectMode.removeListener(widget.model.resetSelection);
    widget.model.resetSelection();
  }

  void _onDeletePress() {
    assert(_multipleSelectMode.value);
    widget.model.removeSelectedAyahs();
    _multipleSelectMode.value = false;
  }

  void _onExitMultiSelectMode() {
    assert(_multipleSelectMode.value == true);
    _multipleSelectMode.toggle();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_multipleSelectMode.value) {
          _multipleSelectMode.value = false;
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Marked ayahs for Para ${widget.model.currentPara}"),
          actions: [
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
          ],
        ),
        body: ListenableBuilder(
          listenable: Listenable.merge([widget.model, _multipleSelectMode]),
          builder: (context, _) {
            return AyatAndMutashabihaListView(
              widget.model.ayahs,
              selectionMode: _multipleSelectMode.value,
              onLongPress: () => _multipleSelectMode.value = true,
            );
          },
        ),
      ),
    );
  }
}
