import 'package:flutter/material.dart';
import 'page_constants.dart';
import 'import_text_page.dart';
import 'settings_page.dart';
import 'para_ayah_selection_page.dart';
import 'ayat.dart';
import 'quiz_para_selection_page.dart';
import 'quiz.dart';
import 'main.dart';
import 'quiz_page.dart';
import 'view_mutashabiha_page.dart';
import 'add_mutashabiha_page.dart';
import 'mutashabihas_page.dart';

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
