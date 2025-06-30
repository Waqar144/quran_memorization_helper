// ignore_for_file: avoid_print
import "dart:io";

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/pages/main_page.dart';
import 'package:quran_memorization_helper/quran_data/pages.dart';
import 'package:quran_memorization_helper/main.dart';
import 'package:quran_memorization_helper/models/settings.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

void main() {
  setUpAll(() async {
    PathProviderPlatform.instance = FakePath();
  });

  testWidgets('Ui_Unit_Test', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const MyApp());

      final mainPageFinder = find.byType(MainPage);
      expect(mainPageFinder, findsOneWidget);

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);

      final state = tester.state<MainPageState>(mainPageFinder);
      print("Start await");
      await state.initialLoadFuture;
      print("End await");

      expect(state.model.bookmarks, isEmpty);
      expect(state.model.ayahs, isEmpty);
      expect(Settings.instance.mushaf, equals(Mushaf.Indopak16Line));

      await tester.pumpAndSettle();

      final pageViewFinder = find.byType(PageView);
      expect(pageViewFinder, findsOneWidget);
      final pageView = tester.widget<PageView>(pageViewFinder);
      expect(pageView.controller, isNotNull);
      expect(pageView.controller!.page!.floor(), equals(0));

      const double speed = 8800;
      const double distance = 200;

      // swipe page
      print("Swipe forward 2 pages");
      await tester.fling(pageViewFinder, Offset((distance), 0), speed);
      await tester.pumpAndSettle();
      expect(pageView.controller!.page!.floor(), equals(1));

      await tester.fling(pageViewFinder, Offset((distance), 0), speed);
      await tester.pumpAndSettle();
      expect(pageView.controller!.page!.floor(), equals(2));

      print("Swipe back now");

      // swipe back
      print("swipe back to page 0");
      await tester.fling(pageViewFinder, Offset(-(distance), 0), speed);
      await tester.pumpAndSettle();
      expect(pageView.controller!.page!.floor(), equals(1));

      await tester.fling(pageViewFinder, Offset(-(distance), 0), speed);
      await tester.pumpAndSettle();
      expect(pageView.controller!.page!.floor(), equals(0));

      print("swipe back, go to last page");
      await tester.fling(pageViewFinder, Offset(-(distance), 0), speed);
      await tester.pumpAndSettle();
      expect(pageView.controller!.page!.floor(), equals(547));

      print("swipe forward again, go to page 0");
      await tester.fling(pageViewFinder, Offset((distance), 0), speed);
      await tester.pumpAndSettle();
      expect(pageView.controller!.page!.floor(), equals(0));

      print("Swipe forward 2 pages, test taping");
      await tester.fling(pageViewFinder, Offset((distance), 0), speed);
      await tester.pumpAndSettle();
      await tester.fling(pageViewFinder, Offset((distance), 0), speed);
      await tester.pumpAndSettle();
      expect(pageView.controller!.page!.floor(), equals(2));

      // tap once, should have a mistake
      await tester.tapAt(Offset(200, 505));
      expect(state.model.ayahs, isNotEmpty);

      // tap once more, mistake is removed
      await tester.tapAt(Offset(200, 505));
      expect(state.model.ayahs, isEmpty);

      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      expect(find.byType(PopupMenuItem<String>), findsNWidgets(5));

      pageView.controller!.jumpToPage(0);
      await tester.pumpAndSettle();

      print("Scroll through all pages");
      for (int i = 0; i < pageCount(Mushaf.Indopak16Line); ++i) {
        pageView.controller!.jumpToPage(i);
        await tester.pumpAndSettle();
        expect(pageView.controller!.page!.floor(), i);
      }

      print("Ui_Unit_Test Ok");
    });
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
