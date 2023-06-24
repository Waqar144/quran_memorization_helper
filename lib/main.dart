import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

import 'ayat.dart';
import 'ayat_list_view.dart';
import 'import_text_page.dart';

const String importTextRoute = "ImportTextRoute";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quran Memorization Helper',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const MainPage(),
      onGenerateRoute: ((settings) {
        if (settings.name == importTextRoute) {
          return MaterialPageRoute(
              builder: (context) => ImportTextPage(settings.arguments as int));
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

class _MainPageState extends State<MainPage> {
  final ParaAyatModel _paraModel = ParaAyatModel();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  final ValueNotifier<bool> _multipleSelectMode = ValueNotifier(false);
  final Set<int> _ayatsIndexesToRemoveInMultiSelectMode = {};

  @override
  void initState() {
    _multipleSelectMode
        .addListener(() => _ayatsIndexesToRemoveInMultiSelectMode.clear());
    _paraModel.onParaChange = (() => _multipleSelectMode.value = false);

    _readJsonFromDisk();
    super.initState();
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

  void _handleClick(String value) {
    switch (value) {
      case 'Add Ayahs...':
        _import();
        break;
      case 'Import Json DB File':
        _importExistingJson();
        break;
    }
  }

  void _showSnackBarMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
      backgroundColor: error ? Colors.red : Colors.green,
    ));
  }

  Future<bool> _readJsonFromDisk({String path = ""}) async {
    bool showError = true;
    if (path.isEmpty) {
      showError = false;
      final Directory dir = await getApplicationDocumentsDirectory();
      path = dir.path;
      path = "$path${Platform.pathSeparator}ayatsdb.json";
    }
    final jsonFile = File(path);
    if (!await jsonFile.exists()) {
      if (showError) _showSnackBarMessage("$path doesn't exist", error: true);
      return false;
    }

    final Map<int, List<Ayat>> paraAyats = {};
    final String contents = await jsonFile.readAsString();
    final Map<String, dynamic> jsonObj = jsonDecode(contents);
    for (final MapEntry<String, dynamic> entry in jsonObj.entries) {
      final int? para = int.tryParse(entry.key);
      if (para == null || para > 30 || para < 1) continue;

      var ayahJsons = entry.value as List<dynamic>?;
      if (ayahJsons == null) continue;
      final List<Ayat> ayats = [
        for (final dynamic a in ayahJsons) Ayat.fromJson(a)
      ];
      paraAyats[para] = ayats;
    }

    _paraModel.setData(paraAyats);
    return true;
  }

  void _saveToDisk() async {
    Directory dir = await getApplicationDocumentsDirectory();
    String path = "${dir.path}${Platform.pathSeparator}ayatsdb.json";
    Map<String, dynamic> out = _paraModel.toJson();
    String json = const JsonEncoder.withIndent("  ").convert(out);
    File f = File(path);
    await f.writeAsString(json);

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

  void _onAyahTapped(int index, bool isSelected) {
    if (_multipleSelectMode.value == false) return;
    if (isSelected) {
      _ayatsIndexesToRemoveInMultiSelectMode.add(index);
    } else {
      _ayatsIndexesToRemoveInMultiSelectMode.remove(index);
    }
  }

  void _onMultiSelectDeletePress() {
    if (_multipleSelectMode.value) {
      _paraModel.removeAyahs(_ayatsIndexesToRemoveInMultiSelectMode);
      // update the db
      _saveToDisk();
    }
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
                      onPressed: _onMultiSelectDeletePress),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _onExitMultiSelectMode),
                ]);
              } else {
                return threeDotMenu!;
              }
            },
            child: PopupMenuButton<String>(
              onSelected: _handleClick,
              icon: const Icon(Icons.more_vert),
              itemBuilder: (BuildContext context) {
                return {'Add Ayahs...', 'Import Json DB File'}
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
        listenable: Listenable.merge([_multipleSelectMode, _paraModel]),
        builder: (context, child) {
          return AyatListView(
              paraAyats: _paraModel.ayahs,
              onTap: _onAyahTapped,
              selectionMode: _multipleSelectMode);
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
