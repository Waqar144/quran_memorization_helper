import 'package:flutter/material.dart';

import 'package:quran_memorization_helper/models/ayat.dart';
import 'package:quran_memorization_helper/models/quiz.dart';
import 'package:quran_memorization_helper/pages/main_page.dart';
import 'package:quran_memorization_helper/pages/page_constants.dart';
import 'package:quran_memorization_helper/pages/import_text_page.dart';
import 'package:quran_memorization_helper/pages/settings_page.dart';
import 'package:quran_memorization_helper/pages/para_ayah_selection_page.dart';
import 'package:quran_memorization_helper/pages/quiz_para_selection_page.dart';
import 'package:quran_memorization_helper/pages/quiz_page.dart';
import 'package:quran_memorization_helper/pages/mutashabihas_page.dart';

MaterialPageRoute handleRoute(RouteSettings settings) {
  if (settings.name == importTextRoute) {
    return MaterialPageRoute(
        builder: (context) => ImportTextPage(settings.arguments as int));
  } else if (settings.name == settingsPageRoute) {
    return MaterialPageRoute(
        builder: (context) =>
            SettingsPage(settings.arguments as ParaAyatModel));
  } else if (settings.name == paraAyahSelectionPage) {
    return MaterialPageRoute(
        builder: (context) => ParaAyahSelectionPage(settings.arguments as int));
  } else if (settings.name == quizSelectionPage) {
    return MaterialPageRoute(builder: (context) => QuizParaSelectionPage());
  } else if (settings.name == quizPage) {
    return MaterialPageRoute(
        builder: (context) => QuizPage(settings.arguments as QuizCreationArgs));
  } else if (settings.name == mutashabihasPage) {
    return MaterialPageRoute(builder: (context) => const MutashabihasPage());
  } else if (settings.name == paraMutashabihasPage) {
    return MaterialPageRoute(
        builder: (context) => ParaMutashabihas(settings.arguments as int));
  }
  return MaterialPageRoute(builder: (context) => const MainPage());
}
