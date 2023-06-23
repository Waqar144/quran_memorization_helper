import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

import 'ayat.dart';
import 'import_text_page.dart';

const String importTextRoute = "ImportTextRoute";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quran Memorization Helper',
      theme: ThemeData(
        primarySwatch: Colors.blue,
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
    _paraModel.onParaChange = ((_) => _multipleSelectMode.value = false);

    _readJsonFromDisk();
    super.initState();
  }

  void _importExistingJson() async {
    // TODO -> use file picker to get file and import
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

  void _onAyahLongPress() {
    setState(() {
      _multipleSelectMode.value = true;
    });
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
    setState(() {
      _multipleSelectMode.value = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
          title: ListenableBuilder(
            listenable: _paraModel,
            builder: (context, _) {
              return Text("Para ${_paraModel.currentPara}");
            },
          ),
          actions: [
            // In Multiselect mode show delete + close
            if (_multipleSelectMode.value) ...[
              IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _onMultiSelectDeletePress),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _onExitMultiSelectMode),
            ] else
              // Otherwise show three dot menu
              PopupMenuButton<String>(
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
          ]),
      body: ListenableBuilder(
        listenable: Listenable.merge([_multipleSelectMode, _paraModel]),
        builder: (context, child) {
          return AyatListView(
              paraAyats: _paraModel.ayahs,
              onTap: _onAyahTapped,
              onLongPress: _onAyahLongPress,
              selectionMode: _multipleSelectMode.value);
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

class AyatListItem extends StatefulWidget {
  const AyatListItem({
    super.key,
    required this.idx,
    required this.text,
    required this.onTap,
    required this.onLongPress,
    required this.selectionMode,
  });

  final int idx;
  final String text;
  final void Function(int index, bool isSelected) onTap;
  final VoidCallback onLongPress;
  final bool selectionMode;

  @override
  State<AyatListItem> createState() => _AyatListItemState();
}

class _AyatListItemState extends State<AyatListItem> {
  bool _selected = false;

  void _longPress() {
    widget.onLongPress();
  }

  void _onTap() {
    setState(() {
      _selected = !_selected;
    });
    widget.onTap(widget.idx, _selected);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: widget.selectionMode
          ? Icon(_selected ? Icons.check_box : Icons.check_box_outline_blank)
          : const Padding(padding: EdgeInsets.zero),
      title: Text(
        widget.text,
        softWrap: true,
        textAlign: TextAlign.right,
        style: const TextStyle(fontFamily: "Al Mushaf", fontSize: 24),
      ),
      onLongPress: widget.selectionMode ? null : _longPress,
      onTap: widget.selectionMode ? _onTap : null,
    );
  }
}

class AyatListView extends StatelessWidget {
  const AyatListView(
      {super.key,
      required this.paraAyats,
      required this.onTap,
      required this.onLongPress,
      required this.selectionMode});

  final List<Ayat> paraAyats;
  final void Function(int index, bool isSelected) onTap;
  final VoidCallback onLongPress;
  final bool selectionMode;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      separatorBuilder: (BuildContext context, int index) =>
          const Divider(indent: 8, endIndent: 8, color: Colors.grey),
      itemCount: paraAyats.length,
      itemBuilder: (context, index) {
        final ayat = paraAyats.elementAt(index);
        final text = ayat.text;
        return AyatListItem(
            key: ObjectKey(ayat),
            text: text,
            idx: index,
            onTap: onTap,
            onLongPress: onLongPress,
            selectionMode: selectionMode);
      },
    );
  }
}
