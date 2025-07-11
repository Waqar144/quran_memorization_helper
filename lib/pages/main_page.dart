import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/models/appbar.dart';
import 'package:quran_memorization_helper/models/ayat.dart';
import 'package:quran_memorization_helper/models/settings.dart';
import 'package:quran_memorization_helper/pages/page_constants.dart';
import 'package:quran_memorization_helper/models/quiz.dart';
import 'package:quran_memorization_helper/quran_data/ayat.dart';
import 'package:quran_memorization_helper/quran_data/pages.dart';
import 'package:quran_memorization_helper/quran_data/quran_text.dart';
import 'package:quran_memorization_helper/quran_data/surahs.dart';
import 'package:quran_memorization_helper/widgets/read_quran.dart';
import 'package:quran_memorization_helper/widgets/surah_list_view.dart';
import 'package:quran_memorization_helper/widgets/para_list_view.dart';
import 'package:quran_memorization_helper/utils/utils.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => MainPageState();
}

@visibleForTesting
class MainPageState extends State<MainPage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final ParaAyatModel _paraModel = ParaAyatModel();
  final ScrollController _scrollController = ScrollController();
  late final TabController _drawerTabController;
  late final AppBarModel _appBarModel;
  late PageController _pageController;
  Mushaf _currentFontStyle = Mushaf.Indopak16Line;
  late final Future<void> _initialLoadFuture;

  ParaAyatModel get model => _paraModel;
  Future<void> get initialLoadFuture => _initialLoadFuture;

  @override
  void initState() {
    _drawerTabController = TabController(length: 2, vsync: this);
    _initialLoadFuture = _load();

    _currentFontStyle = Settings.instance.mushaf;
    QuranText.instance.loadData(_currentFontStyle);

    Settings.instance.addListener(_onSettingsChanged);

    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    _paraModel.dispose();
    WidgetsBinding.instance.removeObserver(this);
    Settings.instance.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (_currentFontStyle != Settings.instance.mushaf) {
      setState(() {
        _currentFontStyle = Settings.instance.mushaf;
        QuranText.instance.loadData(_currentFontStyle);
      });
    }
  }

  Future<void> _load() async {
    final (ok, error) = await _paraModel.readJsonDB();
    if (ok) {
      int jumpToPage = Settings.instance.currentReadingPage;
      try {
        _pageController = PageController(initialPage: jumpToPage);
        _appBarModel = AppBarModel(_paraModel, _goToPage);
      } catch (e) {
        showSnackBarMessage(context, error: true, "Error: $e");
      }
    } else {
      if (mounted) showSnackBarMessage(context, error: true, "Error: $error");
    }
  }

  void _saveScrollPosition(int page) {
    Settings.instance.saveScrollPositionDelayed(page);
  }

  void _resetVerticalScrollToZero() {
    _scrollController.jumpTo(0.0);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      if (!_pageController.hasClients) return;
      await Settings.instance.saveScrollPosition(
        _pageController.page?.floor() ?? 0,
      );
    }
  }

  void _openQuizParaSelectionPage() async {
    final quizCreationArgs =
        await Navigator.of(context).pushNamed(quizSelectionPage)
            as QuizCreationArgs?;
    if (!mounted) return;
    if (quizCreationArgs == null) return;
    if (quizCreationArgs.selectedParas.isEmpty) return;
    final ayahsToAdd =
        await Navigator.of(
              context,
            ).pushNamed(quizPage, arguments: quizCreationArgs)
            as List<Ayat>?;
    if (!mounted) return;
    if (ayahsToAdd == null || ayahsToAdd.isEmpty) return;
    _paraModel.merge(ayahsToAdd);
  }

  void _openSettings() async {
    await Navigator.pushNamed(
      context,
      settingsPageRoute,
      arguments: _paraModel,
    );
  }

  void _openMutashabihat() {
    Navigator.pushNamed(context, mutashabihatPage, arguments: _paraModel);
  }

  void _openMarkedAyahsPage() async {
    final mushaf = Settings.instance.mushaf;
    final para = paraForPage(_pageController.page!.toInt(), mushaf) + 1;
    int? page =
        await Navigator.pushNamed(
              context,
              markedAyahsPage,
              arguments: {'model': _paraModel, 'para': para},
            )
            as int?;
    if (page != null) {
      _goToPage(page, false);
    }
  }

  void _openBookmarksPage() async {
    final res =
        await Navigator.pushNamed(context, bookmarksPage, arguments: _paraModel)
            as int?;
    if (res != null) {
      _goToPage(res, false);
    }
  }

  Widget buildThreeDotMenu() {
    final Map<String, VoidCallback> actions = {
      'Take Quiz': _openQuizParaSelectionPage,
      'Show Marked Ayahs': _openMarkedAyahsPage,
      'Bookmarks': _openBookmarksPage,
      'Mutashabihat': _openMutashabihat,
      'Settings': _openSettings,
    };
    return PopupMenuButton<String>(
      popUpAnimationStyle: AnimationStyle(
        duration: const Duration(milliseconds: 150),
      ),
      onSelected: (String value) {
        final VoidCallback? actionCallback = actions[value];
        if (actionCallback == null) throw "Unknown action: $value";
        actionCallback();
      },
      icon: const Icon(Icons.more_vert),
      itemBuilder: (BuildContext context) {
        return actions.keys.map((String choice) {
          return PopupMenuItem<String>(value: choice, child: Text(choice));
        }).toList();
      },
    );
  }

  void _onSurahTapped(int surahIndex) {
    if (surahIndex >= 0 && surahIndex < 114) {
      final mushaf = Settings.instance.mushaf;
      int jumpToPage = surahStartPage(surahIndex, mushaf);
      _goToPage(jumpToPage, false);
    }
  }

  Future<void> _goToPage(int page, bool animate) async {
    try {
      if (animate) {
        await _pageController.animateToPage(
          page,
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeInOut,
        );
      } else {
        _pageController.jumpToPage(page);
      }
    } catch (e) {
      if (!mounted) return;
      showSnackBarMessage(context, error: true, "Error: $e");
    }
  }

  Widget _buildDrawer() {
    return Builder(
      builder: (context) {
        final int currentPage = (_pageController.page?.floor() ?? 0);
        final int currentParaIdx = paraForPage(
          currentPage,
          Settings.instance.mushaf,
        );
        return Drawer(
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                SizedBox(
                  height: 50,
                  child: TabBar(
                    controller: _drawerTabController,
                    tabs: [Tab(text: paraText()), Tab(text: "Surah")],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _drawerTabController,
                    children: [
                      ParaListView(
                        model: _paraModel,
                        currentParaIdx: currentParaIdx,
                        onParaTapped: (int idx) {
                          final mushaf = Settings.instance.mushaf;
                          _goToPage(paraStartPage(idx, mushaf), false);
                          Navigator.of(context).pop();
                        },
                      ),
                      SurahListView(
                        currentPage: _pageController.page?.floor() ?? 0,
                        onSurahTapped: (int idx) {
                          _onSurahTapped(idx);
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Map<ShortcutActivator, VoidCallback> _shortcutBindings() {
    return <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.arrowLeft):
          () => _appBarModel.nextPage,
      const SingleActivator(LogicalKeyboardKey.arrowRight):
          () => _appBarModel.previousPage,
      const SingleActivator(LogicalKeyboardKey.pageDown):
          () => _appBarModel.nextPage,
      const SingleActivator(LogicalKeyboardKey.pageUp):
          () => _appBarModel.previousPage,
      const SingleActivator(LogicalKeyboardKey.home): () => _goToPage(0, false),
      const SingleActivator(LogicalKeyboardKey.end): () {
        _appBarModel.nextPara(_pageController.page?.round() ?? 0);
        _appBarModel.previousPage(_pageController.page?.round());
      },
      const SingleActivator(LogicalKeyboardKey.arrowLeft, control: true):
          () => _appBarModel.nextPara,
      const SingleActivator(LogicalKeyboardKey.arrowRight, control: true):
          () => _appBarModel.previousPara,
      const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true): () {
        final mushaf = Settings.instance.mushaf;
        int currentPage = _pageController.page?.round() ?? 0;
        int currentSurah = surahForPage(currentPage, mushaf);
        _onSurahTapped(currentSurah == 113 ? 0 : currentSurah + 1);
      },
      const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true): () {
        final mushaf = Settings.instance.mushaf;
        int currentPage = _pageController.page?.round() ?? 0;
        int currentSurah = surahForPage(currentPage, mushaf);
        _onSurahTapped(currentSurah == 0 ? 113 : currentSurah - 1);
      },
    };
  }

  List<Widget> _appBarActions() {
    return [
      TapRegion(
        onTapUpOutside: (_) => _appBarModel.arrowButtonTapUp(),
        onTapUpInside: (_) => _appBarModel.arrowButtonTapUp(),
        child: IconButton(
          tooltip: "Next page",
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _appBarModel.nextPage(_pageController.page?.round()),
          onLongPress: () {
            int page = _pageController.page?.round() ?? 0;
            _appBarModel.longPressFwdBackButton(page, true);
          },
        ),
      ),
      TapRegion(
        onTapUpOutside: (_) => _appBarModel.arrowButtonTapUp(),
        onTapUpInside: (_) => _appBarModel.arrowButtonTapUp(),
        child: IconButton(
          tooltip: "Previous page",
          icon: const Icon(Icons.arrow_forward),
          onPressed:
              () => _appBarModel.previousPage(_pageController.page?.round()),
          onLongPress: () {
            int page = _pageController.page?.round() ?? 0;
            _appBarModel.longPressFwdBackButton(page, false);
          },
        ),
      ),
      IconButton(
        tooltip: "Add Bookmark",
        icon: const Icon(Icons.bookmark),
        onPressed:
            () =>
                _appBarModel.toggleBookmark(_pageController.page?.round() ?? 0),
      ),
      IconButton(
        onPressed: () => _appBarModel.changeTheme(context),
        icon: Icon(
          Theme.of(context).brightness == Brightness.light
              ? Icons.mode_night
              : Icons.light_mode,
        ),
        tooltip:
            Theme.of(context).brightness == Brightness.light
                ? "Switch to night mode"
                : "Switch to light mode",
      ),
      buildThreeDotMenu(),
    ];
  }

  BottomAppBar _bottomAppBar() {
    return BottomAppBar(
      padding: EdgeInsets.zero,
      height: kToolbarHeight,
      child: AppBar(actions: _appBarActions()),
    );
  }

  @override
  void didUpdateWidget(covariant MainPage oldWidget) {
    if (_pageController.initialPage != Settings.instance.currentReadingPage) {
      // This is called right before build(), e.g., when hot reloading or when the
      // widget is rebuilt because settings changed. Update the initialPage of the
      // widget so that we dont end up jumping somewhere else
      _pageController.dispose();
      _pageController = PageController(
        initialPage: Settings.instance.currentReadingPage,
      );
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor:
            Theme.of(context).brightness == Brightness.dark
                ? Colors.black
                : null,
        body: FutureBuilder<void>(
          future: _initialLoadFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Center(child: const CircularProgressIndicator());
            }
            return CallbackShortcuts(
              bindings: _shortcutBindings(),
              child: Focus(
                autofocus: true,
                child: ReadQuranWidget(
                  _paraModel,
                  pageController: _pageController,
                  verticalScrollResetFn: _resetVerticalScrollToZero,
                  pageChangedCallback: _saveScrollPosition,
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: _bottomAppBar(),
        drawer: _buildDrawer(),
      ),
    );
  }
}
