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
    mutashabihasPage =>
      MaterialPageRoute(builder: (ctx) => const MutashabihasPage()),
    // ParaMutashabihas
    paraMutashabihasPage => MaterialPageRoute(
        builder: (ctx) => ParaMutashabihas(settings.arguments as int)),
    // MainPage is the default
    _ => MaterialPageRoute(builder: (ctx) => const MainPage())
  };
}
