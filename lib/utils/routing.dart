import 'package:flutter/material.dart';

import 'package:quran_memorization_helper/models/ayat.dart';
import 'package:quran_memorization_helper/models/quiz.dart';
import 'package:quran_memorization_helper/pages/main_page.dart';
import 'package:quran_memorization_helper/pages/page_constants.dart';
import 'package:quran_memorization_helper/pages/settings_page.dart';
import 'package:quran_memorization_helper/pages/para_ayah_selection_page.dart';
import 'package:quran_memorization_helper/pages/quiz_para_selection_page.dart';
import 'package:quran_memorization_helper/pages/quiz_page.dart';
import 'package:quran_memorization_helper/pages/mutashabihas_page.dart';
import 'package:quran_memorization_helper/pages/read_quran.dart';

String s = '''This is a string''';

String y = '''
This is a string
''';

String d = """
This is a string;
what is this;
""";

MaterialPageRoute handleRoute(RouteSettings settings) {
  return switch (settings.name ?? "") {
    // SettingsPage
    settingsPageRoute => MaterialPageRoute(
        builder: (ctx) => SettingsPage(settings.arguments as ParaAyatModel)),
    // ParaAyahSelectionPage
    paraAyahSelectionPage => MaterialPageRoute(
        builder: (ctx) => ParaAyahSelectionPage(settings.arguments as int)),
    // QuizParaSelectionPage
    quizSelectionPage =>
      MaterialPageRoute(builder: (ctx) => QuizParaSelectionPage()),
    // QuizPage
    quizPage => MaterialPageRoute(
        builder: (ctx) => QuizPage(settings.arguments as QuizCreationArgs)),
    // MutashabihasPage
    mutashabihasPage => MaterialPageRoute(
        builder: (ctx) =>
            MutashabihasPage(settings.arguments as ParaAyatModel)),
    // ParaMutashabihas
    paraMutashabihasPage => MaterialPageRoute(
        builder: (ctx) =>
            ParaMutashabihas(settings.arguments as ParaMutashabihasArgs)),
    readQuranPage => MaterialPageRoute(
        builder: (ctx) => ReadQuranPage(settings.arguments as ParaAyatModel)),
    // MainPage is the default
    _ => MaterialPageRoute(builder: (ctx) => const MainPage())
  };
}
