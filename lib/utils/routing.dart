import 'package:flutter/material.dart';

import 'package:quran_memorization_helper/models/ayat.dart';
import 'package:quran_memorization_helper/models/routing.dart';
import 'package:quran_memorization_helper/pages/main_page.dart';
import 'package:quran_memorization_helper/pages/page_constants.dart';
import 'package:quran_memorization_helper/pages/search_result_page.dart';
import 'package:quran_memorization_helper/pages/settings_page.dart';
import 'package:quran_memorization_helper/pages/quiz_para_selection_page.dart';
import 'package:quran_memorization_helper/pages/quiz_page.dart';
import 'package:quran_memorization_helper/pages/mutashabihas_page.dart';
import 'package:quran_memorization_helper/pages/marked_ayahs_page.dart';
import 'package:quran_memorization_helper/pages/bookmarks_page.dart';
import 'package:quran_memorization_helper/pages/read_only_quran_page.dart';

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
        // MutashabihatPage
        mutashabihatPage => MutashabihatPage(
          settings.arguments as ParaAyatModel,
        ),
        // ParaMutashabihat
        paraMutashabihatPage => ParaMutashabihat(
          settings.arguments as ParaMutashabihatArgs,
        ),
        markedAyahsPage => MarkedAyahsPage(
          settings.arguments as Map<String, dynamic>,
        ),
        // Bookmarks Page
        bookmarksPage => BookmarksPage(
          model: settings.arguments as ParaAyatModel,
        ),
        goToPageModal => ReadOnlyQuranPage(
          settings.arguments as ReadOnlyQuranPageArgs,
        ),
        openSearchPage => QuranSearchPage(settings.arguments as String),
        // MainPage is the default
        _ => const MainPage(),
      };
    },
  );
}
