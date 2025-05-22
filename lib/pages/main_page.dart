import 'package:flutter/material.dart';
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
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final ParaAyatModel _paraModel = ParaAyatModel();
  final ScrollController _scrollController = ScrollController();
  late final TabController _drawerTabController;
  PageController _pageController = PageController(keepPage: false);
  Mushaf _currentFontStyle = Mushaf.Indopak16Line;
  bool _inLongPress = false;
  late final Future<void> _initialLoadFuture;

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
      _pageController.jumpToPage(page);
    }
  }

  void _openBookmarksPage() async {
    final res =
        await Navigator.pushNamed(context, bookmarksPage, arguments: _paraModel)
            as int?;
    if (res != null) {
      _pageController.jumpToPage(res);
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

  void _onSurahTapped(int surahIndex, {bool pop = true}) {
    if (pop) Navigator.of(context).pop();
    if (surahIndex < 0 || surahIndex > 113) {
      return;
    }
    try {
      final mushaf = Settings.instance.mushaf;
      int jumpToPage = surahStartPage(surahIndex, mushaf);
      _pageController.jumpToPage(jumpToPage);
    } catch (e) {
      showSnackBarMessage(context, error: true, "Error: $e");
    }
  }

  void _nextPage() {
    int? currentPage = _pageController.page?.floor();
    final mushaf = Settings.instance.mushaf;
    int totalPages = pageCount(mushaf);
    int nextPage = (currentPage ?? -1) + 1;
    if (nextPage >= totalPages) {
      _pageController.jumpToPage(0);
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    int? currentPage = _pageController.page?.floor();
    int previousPage = (currentPage ?? 1) - 1;
    if (previousPage < 0) {
      final mushaf = Settings.instance.mushaf;
      _pageController.jumpToPage(pageCount(mushaf));
    } else {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextPara() {
    final mushaf = Settings.instance.mushaf;
    final current = paraForPage(_pageController.page!.toInt(), mushaf);
    if (current == 29) {
      _pageController.jumpToPage(0);
    } else {
      _pageController.jumpToPage(paraStartPage(current + 1, mushaf));
    }
  }

  void _previousPara() {
    final mushaf = Settings.instance.mushaf;
    final current = paraForPage(_pageController.page!.toInt(), mushaf);
    if (current == 0) {
      _pageController.jumpToPage(paraStartPage(29, mushaf));
    } else {
      _pageController.jumpToPage(paraStartPage(current - 1, mushaf));
    }
  }

  void _longPressFwdBackButton(bool fwd) async {
    _inLongPress = true;
    int currentPage = _pageController.page?.floor() ?? 0;
    final mushaf = Settings.instance.mushaf;
    int totalPages = pageCount(mushaf);
    final func = fwd ? _pageController.nextPage : _pageController.previousPage;
    final offset = fwd ? 1 : -1;

    while (currentPage < totalPages) {
      if (_inLongPress == false) break;
      await func(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
      );
      currentPage += offset;
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
                          _pageController.jumpToPage(
                            paraStartPage(idx, mushaf),
                          );
                          Navigator.of(context).pop();
                        },
                      ),
                      SurahListView(
                        currentPage: _pageController.page?.floor() ?? 0,
                        onSurahTapped: _onSurahTapped,
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
      const SingleActivator(LogicalKeyboardKey.arrowLeft): _nextPage,
      const SingleActivator(LogicalKeyboardKey.arrowRight): _previousPage,
      const SingleActivator(LogicalKeyboardKey.pageDown): _nextPage,
      const SingleActivator(LogicalKeyboardKey.pageUp): _previousPage,
      const SingleActivator(LogicalKeyboardKey.home):
          () => _pageController.jumpToPage(0),
      const SingleActivator(LogicalKeyboardKey.end): () {
        _nextPara();
        _previousPage();
      },
      const SingleActivator(LogicalKeyboardKey.arrowLeft, control: true):
          _nextPara,
      const SingleActivator(LogicalKeyboardKey.arrowRight, control: true):
          _previousPara,
      const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true): () {
        final mushaf = Settings.instance.mushaf;
        int currentPage = _pageController.page?.floor() ?? 0;
        int currentSurah = surahForPage(currentPage, mushaf);
        _onSurahTapped(currentSurah == 113 ? 0 : currentSurah + 1, pop: false);
      },
      const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true): () {
        final mushaf = Settings.instance.mushaf;
        int currentPage = _pageController.page?.floor() ?? 0;
        int currentSurah = surahForPage(currentPage, mushaf);
        _onSurahTapped(currentSurah == 0 ? 113 : currentSurah - 1, pop: false);
      },
    };
  }

  List<Widget> _appBarActions() {
    return [
      TapRegion(
        onTapUpOutside: (_) => _inLongPress = false,
        onTapUpInside: (_) => _inLongPress = false,
        child: IconButton(
          tooltip: "Next ${paraText()}",
          icon: const Icon(Icons.arrow_back),
          onPressed: _nextPara,
          onLongPress: () => _longPressFwdBackButton(true),
        ),
      ),
      TapRegion(
        onTapUpOutside: (_) => _inLongPress = false,
        onTapUpInside: (_) => _inLongPress = false,
        child: IconButton(
          tooltip: "Previous ${paraText()}",
          icon: const Icon(Icons.arrow_forward),
          onPressed: _previousPara,
          onLongPress: () => _longPressFwdBackButton(false),
        ),
      ),
      IconButton(
        tooltip: "Add Bookmark",
        icon: const Icon(Icons.bookmark),
        onPressed: () {
          final page = _pageController.page!.floor();
          if (_paraModel.bookmarks.contains(page)) {
            _paraModel.removeBookmark(page);
          } else {
            _paraModel.addBookmark(page);
          }
        },
      ),
      IconButton(
        onPressed: () {
          if (Theme.of(context).brightness == Brightness.dark) {
            Settings.instance.themeMode = ThemeMode.light;
          } else {
            Settings.instance.themeMode = ThemeMode.dark;
          }
        },
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

  AppBar _buildAppBar() {
    return AppBar(actions: _appBarActions());
  }

  BottomAppBar _bottomAppBar() {
    return BottomAppBar(
      padding: EdgeInsets.zero,
      height: kToolbarHeight,
      child: _buildAppBar(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Theme.of(context).brightness == Brightness.dark ? Colors.black : null,
      appBar: Settings.instance.bottomAppBar ? null : _buildAppBar(),
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
      bottomNavigationBar:
          Settings.instance.bottomAppBar ? _bottomAppBar() : null,
      drawer: _buildDrawer(),
    );
  }
}
