import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'ayat.dart';
import 'ayat_list_view.dart';
import 'settings.dart';
import 'page_constants.dart';
import 'routing.dart';
import 'quiz.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quran Revision Helper',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const MainPage(),
      onGenerateRoute: handleRoute,
    );
  }
}

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
        _showSnackBarMessage("${result.names.first} imported successfully");
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

  void _showSnackBarMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
      backgroundColor: error ? Colors.red : Colors.green,
    ));
  }

  Future<bool> _readJsonFromDisk({String? path}) async {
    final bool showError = path != null;
    final bool result = await _paraModel.readJsonDB(path: path);
    if (!result && showError) {
      _showSnackBarMessage("$path doesn't exist", error: true);
      return false;
    }
    return true;
  }

  void _saveToDisk() async {
    String path = await _paraModel.saveToDisk();
    _showSnackBarMessage("Saved to file $path");
  }

  void _import() async {
    final dynamic result = await Navigator.pushNamed(context, importTextRoute,
        arguments: _paraModel.currentPara);
    if (!mounted) return;

    List<Ayat>? importedAyats = result as List<Ayat>?;
    if (importedAyats == null) return;

    // merge new and old ayahs
    final existingAyahs = _paraModel.ayahs;
    Set<Ayat> newAyahs = {};
    newAyahs.addAll(existingAyahs);
    newAyahs.addAll(importedAyats);
    if (newAyahs.isEmpty) return;
    _paraModel.setAyahs(newAyahs.toList());

    _showSnackBarMessage(
        "Imported ${importedAyats.length} ayahs into Para ${_paraModel.currentPara}");

    _saveToDisk();
  }

  void _openSettings() async {
    await Navigator.pushNamed(context, settingsPageRoute,
        arguments: _paraModel);
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
      'Add Ayahs...': _import,
      'Take Quiz': _openQuizParaSelectionPage,
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
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        elevation: 1,
        scrolledUnderElevation: 2,
        shadowColor: Theme.of(context).shadowColor,
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
          return AyatListView(
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
    );
  }
}
