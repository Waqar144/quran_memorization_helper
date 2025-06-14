import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/models/ayah_selection_model.dart';
import 'package:quran_memorization_helper/models/ayat.dart';
import 'package:quran_memorization_helper/models/settings.dart';
import 'package:quran_memorization_helper/quran_data/ayat.dart';
import 'package:quran_memorization_helper/quran_data/para_bounds.dart';
import 'package:quran_memorization_helper/utils/utils.dart';
import 'package:quran_memorization_helper/widgets/ayat_and_mutashabiha_list_view.dart';

class MarkedAyahsPage extends StatefulWidget {
  final ParaAyatModel model;
  final int para;
  MarkedAyahsPage(Map<String, dynamic> args, {super.key})
    : model = args['model'],
      para = args['para'];
  @override
  State<StatefulWidget> createState() => _MarkedAyahsPageState();
}

class _MarkedAyahsPageState extends State<MarkedAyahsPage> {
  int _currentPara = 1;
  bool _multipleSelectMode = false;
  List<AyatOrMutashabiha> ayahAndMutashabihat = [];
  AyahSelectionState _selectionState = AyahSelectionState.fromAyahs([]);
  late Future<void> _loadDataFuture;

  @override
  void initState() {
    _currentPara = widget.para;
    onModelChanged();
    widget.model.addListener(onModelChanged);
    super.initState();
  }

  @override
  void dispose() {
    widget.model.removeListener(onModelChanged);
    super.dispose();
  }

  void onModelChanged() {
    setState(() {
      _loadDataFuture = _load();
    });
  }

  void _onDeletePress() {
    assert(_multipleSelectMode);
    final List<int> ayahsToRemove = _selectionState.selectedAyahs();
    if (ayahsToRemove.isEmpty) return;
    widget.model.removeAyahs(ayahsToRemove);
    _onExitMultiSelectMode();
  }

  void _onExitMultiSelectMode() {
    if (_multipleSelectMode) {
      setState(() {
        _multipleSelectMode = false;
        _selectionState.clearSelection();
      });
    }
  }

  void _enterMultiselectMode() {
    setState(() {
      _multipleSelectMode = true;
    });
  }

  void _onTap(int ayahIndex) {
    _selectionState.toggle(ayahIndex);
    setState(() {});
  }

  void _onGotoAyah(int ayahIndex) {
    int page = getPageForAyah(ayahIndex, Settings.instance.mushaf);
    Navigator.of(context).pop(page);
  }

  Future<void> _load() async {
    final List<Mutashabiha> mutashabihat = await importParaMutashabihat(
      _currentPara - 1,
    );

    ayahAndMutashabihat = widget.model.ayahsAndMutashabihatList(
      _currentPara,
      mutashabihat,
    );
    for (final a in ayahAndMutashabihat) {
      a.ensureTextIsLoaded();
    }
    _selectionState = AyahSelectionState.fromAyahs(ayahAndMutashabihat);
  }

  AppBar buildAppbar() {
    return AppBar(
      title: Text(
        "Marked ayahs for ${paraText()} $_currentPara",
        style: TextStyle(fontSize: 18),
      ),
      actions:
          _multipleSelectMode
              ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _onDeletePress,
                ),
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: () {
                    setState(() => _selectionState.selectAll());
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _onExitMultiSelectMode,
                ),
              ]
              : [
                IconButton(
                  tooltip: "Next ${paraText()}",
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    _currentPara = _currentPara >= 30 ? 1 : _currentPara + 1;
                    onModelChanged();
                  },
                ),
                IconButton(
                  tooltip: "Previous ${paraText()}",
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () {
                    _currentPara = _currentPara <= 1 ? 30 : _currentPara - 1;
                    onModelChanged();
                  },
                ),
              ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _multipleSelectMode == false,
      onPopInvokedWithResult: (didPop, result) async {
        if (_multipleSelectMode) {
          _onExitMultiSelectMode();
        }
      },
      child: Scaffold(
        appBar: buildAppbar(),
        body: FutureBuilder<void>(
          future: _loadDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox.shrink();
            }
            return AyatAndMutashabihaListView(
              ayahAndMutashabihat,
              selectionState: _selectionState,
              selectionMode: _multipleSelectMode,
              onLongPress: _enterMultiselectMode,
              onTap: _onTap,
              onGotoAyah: _onGotoAyah,
            );
          },
        ),
      ),
    );
  }
}
