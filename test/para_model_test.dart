// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';

import 'package:path_provider/path_provider.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'dart:io';
import 'dart:convert';

import 'package:quran_memorization_helper/models/ayat.dart';
import 'package:quran_memorization_helper/quran_data/ayat.dart';

Future<String> getDocPath() async {
  Directory docs = await getApplicationDocumentsDirectory();
  return docs.path;
}

dynamic getDiskJson() async {
  final path = await getDocPath();
  File jsonFile = File("$path${Platform.pathSeparator}ayatsdb.json");
  String jsonText = await jsonFile.readAsString();
  return jsonDecode(jsonText);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  ParaAyatModel model = ParaAyatModel();

  setUpAll(() async {
    PathProviderPlatform.instance = FakePath();
    Directory docs = await getApplicationDocumentsDirectory();
    File jsonFile = File("${docs.path}${Platform.pathSeparator}ayatsdb.json");
    await jsonFile.writeAsString(initData);
    print("Created test db ${jsonFile.path}");
    await model.readJsonDB();
  });

  test("ParaAyatModel initial state", () async {
    expect(model.ayahs.length, 3);
    await model.saveToDisk();

    final diskJson = await getDiskJson();
    final expected = jsonDecode('''{
  "ayats": [
      {"idx": 9, "words": [0]},
      {"idx": 141, "words": [0]},
      {"idx": 144, "words": [0]}
  ],
  "version": 1
  }''');
    expect(diskJson, equals(expected));
  });

  test('ParaAyatModel test modify model', () async {
    expect(model.ayahs.length, 3);

    model.addAyahs([]);
    expect(model.ayahs.length, 3);

    model.addAyahs([
      Ayat("", [0], ayahIdx: 4),
    ]);
    expect(model.ayahs.length, 4);
    expect(model.timer!.isActive, isTrue);

    expect(model.ayahs.first.ayahIdx, 4);

    // wait one and a half second for save to happen
    await Future.delayed(const Duration(seconds: 1, milliseconds: 500), () {});

    // our backup file should be there
    final docPath = await getDocPath();
    expect(
      File("$docPath${Platform.pathSeparator}ayatsdb_bck.json").existsSync(),
      isTrue,
    );

    model.removeMarkedWordInAyat(4, 0);
    expect(model.ayahs.length, 3);
    expect(model.timer!.isActive, isTrue);

    model.addAyahs([
      Ayat("", [0], ayahIdx: 4),
      Ayat("", [0], ayahIdx: 5),
      Ayat("", [0], ayahIdx: 6),
    ]);
    model.removeAyahs([4, 5, 6]);
    expect(model.ayahs.length, 3);
    expect(model.timer!.isActive, isTrue);

    print("test modify model OK");
  });

  test('ParaAyatModel test add invalid ayah', () async {
    expect(model.ayahs.length, 3);

    model.addAyahs([
      Ayat("", [0], ayahIdx: 9999),
    ]);
    expect(model.ayahs.length, 3);

    print("test add invalid ayah OK");
  });

  tearDownAll(() async {
    Directory docs = await getApplicationDocumentsDirectory();
    File jsonFile = File("${docs.path}${Platform.pathSeparator}ayatsdb.json");
    File jsonBckFile = File(
      "${docs.path}${Platform.pathSeparator}ayatsdb_bck.json",
    );
    await jsonFile.delete();
    print("deleted test db file");
    if (jsonBckFile.existsSync()) {
      await jsonBckFile.delete();
      print("deleted test db backup file");
    }
  });
}

class FakePath extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String> getApplicationDocumentsPath() async {
    return Directory.current.path;
  }
}

String initData = '''
{
  "1": {
    "ayats": [
      {"idx": 9, "words": [0]},
      {"idx": 141, "words": [0]},
      {"idx": 144, "words": [0]}
    ]
  },
  "currentPara": 3
}
''';
