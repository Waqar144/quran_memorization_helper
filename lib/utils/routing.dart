import 'package:flutter/material.dart';

import 'package:quran_memorization_helper/models/ayat.dart';
import 'package:quran_memorization_helper/models/quiz.dart';
import 'package:quran_memorization_helper/pages/main_page.dart';
import 'package:quran_memorization_helper/pages/page_constants.dart';
import 'package:quran_memorization_helper/pages/settings_page.dart';
import 'package:quran_memorization_helper/pages/quiz_para_selection_page.dart';
import 'package:quran_memorization_helper/pages/quiz_page.dart';
import 'package:quran_memorization_helper/pages/mutashabihas_page.dart';
import 'package:quran_memorization_helper/pages/marked_ayahs_page.dart';

MaterialPageRoute handleRoute(RouteSettings settings) {
  return MaterialPageRoute(
    builder: (ctx) {
      return switch (settings.name ?? "") {
        // SettingsPage
        settingsPageRoute => SettingsPage(settings.arguments as ParaAyatModel),
        // QuizParaSelectionPage
        quizSelectionPage => QuizParaSelectionPage(),
        // QuizPage
        quizPage => QuizPage(settings.arguments as QuizCreationArgs),
        // MutashabihasPage
        mutashabihasPage => const MutashabihasPage(),
        // ParaMutashabihas
        paraMutashabihasPage => ParaMutashabihas(settings.arguments as int),
        markedAyahsPage => MarkedAyahsPage(settings.arguments as ParaAyatModel),
        // MainPage is the default
        _ => const MainPage(),
      };
    },
  );
}
