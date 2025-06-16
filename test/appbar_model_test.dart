// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_memorization_helper/models/appbar.dart';
import 'package:quran_memorization_helper/models/ayat.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:quran_memorization_helper/models/settings.dart';

void main() {
  ParaAyatModel model = ParaAyatModel();
  int resultPage = -1;

  Future<void> testGoToPage(int page, bool animate) async {
    resultPage = page;
  }

  Future<void> testGoToPageAnimated(int page, bool animate) async {
    await Future.delayed(const Duration(milliseconds: 120), () {});
    resultPage = page;
  }

  setUpAll(() async {
    PathProviderPlatform.instance = FakePath();
    Settings.instance.mushaf = Mushaf.Indopak16Line;
  });

  test("test appbar model", () async {
    AppBarModel m = AppBarModel(model, testGoToPage);
    m.nextPage(0);
    expect(1, resultPage);

    m.previousPage(resultPage);
    expect(0, resultPage);

    m.nextPara(resultPage);
    expect(19, resultPage);

    m.previousPara(resultPage);
    expect(0, resultPage);

    m.nextPage(null);
    expect(0, resultPage);

    m.previousPage(null);
    expect(0, resultPage);

    m.toggleBookmark(0);
    expect(model.bookmarks.contains(0), true);
    m.toggleBookmark(0);
    expect(model.bookmarks.contains(0), false);

    m = AppBarModel(model, testGoToPageAnimated);

    Future.delayed(const Duration(milliseconds: 300), () {
      m.arrowButtonTapUp();
    });
    await m.longPressFwdBackButton(0, true);
    expect(resultPage, greaterThanOrEqualTo(2));

    Future.delayed(const Duration(milliseconds: 400), () {
      m.arrowButtonTapUp();
    });
    await m.longPressFwdBackButton(0, false);
    expect(resultPage, equals(0));

    print("test appbar model Ok");
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
