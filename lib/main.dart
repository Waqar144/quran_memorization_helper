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
  Map<int, List<Ayat>> _paraAyats = {};
  int _currentPara = 1;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  @override
  void initState() {
    _readJsonFromDisk();
    super.initState();
  }

  void _importExistingJson() {
    // TODO -> use file picker to get file and import
  }

  void _setCurrentPara(int index) {
    setState(() {
      _currentPara = index;
      _scaffoldKey.currentState?.closeDrawer();
    });
  }

  void _handleClick(String value) {
    switch (value) {
      case 'Import Ayahs...':
        _import();
        break;
      case 'Import Json DB File':
        _importExistingJson();
        break;
    }
  }

  void _showSnackBarMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.green,
    ));
  }

  void _readJsonFromDisk({String path = ""}) async {
    if (path.isEmpty) {
      final Directory dir = await getApplicationDocumentsDirectory();
      path = dir.path;
    }
    final String jsonFilePath = "$path${Platform.pathSeparator}ayatsdb.json";
    final jsonFile = File(jsonFilePath);
    if (!await jsonFile.exists()) return;

    final Map<int, List<Ayat>> paraAyats = {};
    _paraAyats.clear();
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

    setState(() {
      _paraAyats = paraAyats;
    });
  }

  void _saveToDisk() async {
    Directory dir = await getApplicationDocumentsDirectory();
    String path = "${dir.path}${Platform.pathSeparator}ayatsdb.json";
    Map<String, dynamic> out = {};
    _paraAyats.forEach((int para, List<Ayat> ayats) {
      out.putIfAbsent(para.toString(), () => ayats);
    });
    String json = const JsonEncoder.withIndent("  ").convert(out);
    File f = File(path);
    await f.writeAsString(json);

    _showSnackBarMessage("Saved to file $path");
  }

  void _import() async {
    final dynamic result = await Navigator.pushNamed(context, importTextRoute,
        arguments: _currentPara);
    if (!mounted) return;

    List<Ayat>? importedAyats = result as List<Ayat>?;
    if (importedAyats == null) return;

    _showSnackBarMessage(
        "Imported ${importedAyats.length} ayahs into $_currentPara");
    setState(() {
      _paraAyats[_currentPara] = importedAyats;
    });

    _saveToDisk();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(),
      body: ListView.separated(
        separatorBuilder: (BuildContext context, int index) =>
            const Divider(indent: 8, endIndent: 8, color: Colors.grey),
        itemCount: _paraAyats[_currentPara]?.length ?? 0,
        itemBuilder: (context, index) {
          final text = _paraAyats[_currentPara]?.elementAt(index).text ?? "";
          return AyatListItem(text: text);
        },
      ),
      drawer: Drawer(
        child: ListView.builder(
          itemCount: 30,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text("Para ${index + 1}"),
              onTap: () => _setCurrentPara(index + 1),
            );
          },
        ),
      ),
      floatingActionButton: PopupMenuButton<String>(
        onSelected: _handleClick,
        surfaceTintColor: Colors.red,
        itemBuilder: (BuildContext context) {
          return {'Import Ayahs...', 'Import Json DB File'}
              .map((String choice) {
            return PopupMenuItem<String>(
              value: choice,
              child: Text(choice),
            );
          }).toList();
        },
        child: const FloatingActionButton(
          onPressed: null,
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}

class AyatListItem extends StatefulWidget {
  const AyatListItem({super.key, required this.text});

  final String text;

  @override
  State<AyatListItem> createState() => _AyatListItemState();
}

class _AyatListItemState extends State<AyatListItem> {
  void _longPress() {
    print("TODO Long press\n");
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ListTile(
            title: Text(
              widget.text,
              softWrap: true,
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: "Al Mushaf", fontSize: 24),
            ),
            onLongPress: _longPress,
          ),
        ]);
  }
}
