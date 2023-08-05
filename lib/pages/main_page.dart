import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/models/ayat.dart';
import 'package:quran_memorization_helper/widgets/ayat_and_mutashabiha_list_view.dart';
import 'package:quran_memorization_helper/models/settings.dart';
import 'package:file_picker/file_picker.dart';
import 'package:quran_memorization_helper/pages/page_constants.dart';
import 'package:quran_memorization_helper/models/quiz.dart';
import 'package:quran_memorization_helper/quran_data/ayat.dart';
import 'package:quran_memorization_helper/utils/utils.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  final ParaAyatModel _paraModel = ParaAyatModel();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  final ValueNotifier<bool> _multipleSelectMode = ValueNotifier(false);

  @override
  void initState() {
    _multipleSelectMode.addListener(() => _paraModel.resetSelection());
    _paraModel.onParaChange = (() => _multipleSelectMode.value = false);

    _readJsonFromDisk();
    Settings.instance.readSettings();

    super.initState();
  }

  @override
  void dispose() {
    _paraModel.dispose();
    _multipleSelectMode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _saveToDisk();
    }
    super.didChangeAppLifecycleState(state);
  }

  void _importExistingJson() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: "Select JSON File",
        type: FileType.custom,
        allowedExtensions: ["json"]);
    if (result != null && result.paths.isNotEmpty) {
      String? path = result.paths.first;
      if (path == null) return;
      if (await _readJsonFromDisk(path: path)) {
        if (mounted) {
          showSnackBarMessage(
              context, "${result.names.first} imported successfully");
        }
        _saveToDisk();
      }
    }
  }

  void _openQuizParaSelectionPage() async {
    final quizCreationArgs = await Navigator.of(context)
        .pushNamed(quizSelectionPage) as QuizCreationArgs?;
    if (!mounted || quizCreationArgs == null) return;
    if (quizCreationArgs.selectedParas.isEmpty) return;
    final ayahsToAdd = await Navigator.of(context).pushNamed(quizPage,
        arguments: quizCreationArgs) as Map<int, List<Ayat>>?;
    if (!mounted) return;
    if (ayahsToAdd == null || ayahsToAdd.isEmpty) return;
    _paraModel.merge(ayahsToAdd);
  }

  Future<bool> _readJsonFromDisk({String? path}) async {
    final bool showError = path != null;
    final bool result = await _paraModel.readJsonDB(path: path);
    if (!result && showError && mounted) {
      showSnackBarMessage(context, "$path doesn't exist", error: true);
      return false;
    }
    return true;
  }

  void _saveToDisk() async {
    String path = await _paraModel.saveToDisk();
    if (mounted) return;
    showSnackBarMessage(context, "Saved to file $path");
  }

  void _addAyahs() async {
    final dynamic result = await Navigator.pushNamed(
      context,
      paraAyahSelectionPage,
      arguments: _paraModel.currentPara,
    );

    if (!mounted) return;

    List<Ayat>? importedAyats = result as List<Ayat>?;
    if (importedAyats == null) return;
    _paraModel.addAyahs(importedAyats);

    showSnackBarMessage(context,
        "Imported ${importedAyats.length} ayahs into Para ${_paraModel.currentPara}");

    _saveToDisk();
  }

  void _openSettings() async {
    await Navigator.pushNamed(context, settingsPageRoute,
        arguments: _paraModel);
  }

  void _openMutashabihas() {
    Navigator.pushNamed(context, mutashabihasPage, arguments: _paraModel);
  }

  void _onDeletePress() {
    assert(_multipleSelectMode.value);
    _paraModel.removeSelectedAyahs();
    // update the db
    _saveToDisk();
  }

  void _onExitMultiSelectMode() {
    assert(_multipleSelectMode.value == true);
    _multipleSelectMode.toggle();
  }

  Widget buildThreeDotMenu() {
    final Map<String, VoidCallback> actions = {
      'Add Ayahs...': _addAyahs,
      'Take Quiz': _openQuizParaSelectionPage,
      'Mutashabihas': _openMutashabihas,
      'Import Json DB File': _importExistingJson,
      'Settings': _openSettings,
    };
    return PopupMenuButton<String>(
      onSelected: (String value) {
        final actionCallback = actions[value];
        if (actionCallback == null) throw "Unknown action: $value";
        actionCallback();
      },
      icon: const Icon(Icons.more_vert),
      itemBuilder: (BuildContext context) {
        return actions.keys.map((String choice) {
          return PopupMenuItem<String>(
            value: choice,
            child: Text(choice),
          );
        }).toList();
      },
    );
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
        key: _scaffoldKey,
        appBar: AppBar(
          title: ValueListenableBuilder(
            valueListenable: _paraModel.currentParaNotifier,
            builder: (context, value, _) {
              return Text("Para $value");
            },
          ),
          actions: [
            ValueListenableBuilder<bool>(
              valueListenable: _multipleSelectMode,
              builder: (context, value, threeDotMenu) {
                if (value) {
                  return Row(children: [
                    IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: _onDeletePress),
                    IconButton(
                        icon: const Icon(Icons.select_all),
                        onPressed: () => _paraModel.selectAll()),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _onExitMultiSelectMode),
                  ]);
                } else {
                  return threeDotMenu!;
                }
              },
              child: buildThreeDotMenu(),
            ),
          ],
        ),
        body: ListenableBuilder(
          listenable: Listenable.merge(
              [_multipleSelectMode, _paraModel, Settings.instance]),
          builder: (context, child) {
            return AyatAndMutashabihaListView(
              _paraModel.ayahs,
              selectionMode: _multipleSelectMode.value,
              onLongPress: _multipleSelectMode.toggle,
            );
          },
        ),
        drawer: Drawer(
          child: ListView.builder(
            itemCount: 30,
            itemBuilder: (context, index) {
              return ListTile(
                minVerticalPadding: 0,
                visualDensity: VisualDensity.compact,
                title: Text("Para ${index + 1}"),
                onTap: () {
                  _paraModel.setCurrentPara(index + 1);
                  _scaffoldKey.currentState?.closeDrawer();
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
