import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'ayat.dart';
import 'ayat_list_view.dart';
import 'import_text_page.dart';
import 'settings_page.dart';
import 'settings.dart';
import 'page_constants.dart';
import 'para_ayah_selection_page.dart';

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
      onGenerateRoute: ((settings) {
        if (settings.name == importTextRoute) {
          return MaterialPageRoute(
              builder: (context) => ImportTextPage(settings.arguments as int));
        } else if (settings.name == settingsPageRoute) {
          return MaterialPageRoute(
              builder: (context) =>
                  SettingsPage(settings.arguments as ParaAyatModel));
        } else if (settings.name == paraAyahSelectionPage) {
          return MaterialPageRoute(
              builder: (context) =>
                  ParaAyahSelectionPage(settings.arguments as int));
        }
        return MaterialPageRoute(builder: (context) => const MainPage());
      }),
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
            child: PopupMenuButton<String>(
              onSelected: (String value) {
                switch (value) {
                  case 'Add Ayahs...':
                    _import();
                    break;
                  case 'Import Json DB File':
                    _importExistingJson();
                    break;
                  case 'Settings':
                    _openSettings();
                    break;
                }
              },
              icon: const Icon(Icons.more_vert),
              itemBuilder: (BuildContext context) {
                return {'Add Ayahs...', 'Import Json DB File', 'Settings'}
                    .map((String choice) {
                  return PopupMenuItem<String>(
                    value: choice,
                    child: Text(choice),
                  );
                }).toList();
              },
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge(
            [_multipleSelectMode, _paraModel, Settings.instance]),
        builder: (context, child) {
          return AyatListView(_paraModel, selectionMode: _multipleSelectMode);
        },
      ),
      drawer: Drawer(
        child: ListView.builder(
          itemCount: 30,
          itemBuilder: (context, index) {
            return ListTile(
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
