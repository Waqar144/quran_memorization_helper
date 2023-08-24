// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';

import 'package:quran_memorization_helper/models/ayat.dart';
import 'package:path_provider/path_provider.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  ParaAyatModel model = ParaAyatModel();

  setUp(() async {
    PathProviderPlatform.instance = FakePath();
    Directory docs = await getApplicationDocumentsDirectory();
    File jsonFile = File("${docs.path}${Platform.pathSeparator}ayatsdb.json");
    await jsonFile.writeAsString(initData);
    print("Created test db ${jsonFile.path}");
    await model.readJsonDB();
  });

  test('test current para', () {
    expect(model.currentPara, 3);
    expect(model.ayahs.length, 0);
  });

  tearDown(() async {
    Directory docs = await getApplicationDocumentsDirectory();
    File jsonFile = File("${docs.path}${Platform.pathSeparator}ayatsdb.json");
    await jsonFile.delete();
    print("deleted test db file");
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
      141,
      144
    ],
    "mutashabihas": [
      {
        "src": {
          "ayah": 9
        },
        "muts": [
          {
            "ayah": 1162
          },
          {
            "ayah": 3161
          },
          {
            "ayah": 3472
          }
        ]
      }
    ]
  },
  "currentPara": 3
}
''';
