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
  late final ParaAyatModel _paraModel;
  final ScrollController _scrollController = ScrollController();
  late final TabController _drawerTabController;
  PageController _pageController = PageController(keepPage: false);
  Mushaf _currentFontStyle = Mushaf.Indopak16Line;

  @override
  void initState() {
    _paraModel = ParaAyatModel(onParaChanged);
    _drawerTabController = TabController(length: 2, vsync: this);

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

  void onParaChanged(int para, bool showLastPage, int jumpToPage) {
    // if para is same
    if (para == _paraModel.currentPara && _pageController.hasClients) {
      // page also same?
      if (jumpToPage != -1 &&
          _pageController.page != null &&
          (jumpToPage - 1) == _pageController.page!.toInt()) {
        return;
      }
      // try to jump to page
      _pageController.jumpToPage(jumpToPage - 1);
      return;
    }

    _pageController.dispose();
    int page = 1;
    if (showLastPage) {
      page = pageCountForPara(para - 1);
    }
    if (jumpToPage != -1) {
      page = jumpToPage;
    }

    _pageController = PageController(initialPage: (page - 1), keepPage: false);
    // reinstall listeners
    _pageController.removeListener(_saveScrollPosition);
    _pageController.addListener(_saveScrollPosition);
  }

  Future<void> _load() async {
    final (ok, error) = await _paraModel.readJsonDB();
    if (ok) {
      // If the para is same as what's in settings, then try to restore scroll position
      int jumpToPage = 0;
      if (Settings.instance.currentReadingPara == _paraModel.currentPara) {
        jumpToPage = Settings.instance.currentReadingPage + 1;
      }
      try {
        onParaChanged(_paraModel.currentPara, false, jumpToPage);
      } catch (e) {
        showSnackBarMessage(context, error: true, "Error: $e");
      }
    } else {
      if (mounted) showSnackBarMessage(context, error: true, "Error: $error");
    }
  }

  void _saveScrollPosition() {
    // multiply by 500 to make the offset bigger so it can be saved, otherwise it gets ignored
    // as the difference between last save value and this one might be too small
    Settings.instance.saveScrollPositionDelayed(
      _paraModel.currentPara,
      _pageController.page?.floor() ?? 0,
    );
  }

  void _resetVerticalScrollToZero() {
    _scrollController.jumpTo(0.0);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      await Settings.instance.saveScrollPosition(
        _paraModel.currentPara,
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
            as Map<int, List<Ayat>>?;
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

  void _openMutashabihas() {
    Navigator.pushNamed(context, mutashabihasPage, arguments: _paraModel);
  }

  void _openMarkedAyahsPage() async {
    Navigator.pushNamed(context, markedAyahsPage, arguments: _paraModel);
  }

  Widget buildThreeDotMenu() {
    final Map<String, VoidCallback> actions = {
      'Take Quiz': _openQuizParaSelectionPage,
      'Show Marked Ayahs': _openMarkedAyahsPage,
      'Mutashabihas': _openMutashabihas,
      'Settings': _openSettings,
    };
    return PopupMenuButton<String>(
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
      final is16line = Settings.instance.mushaf == Mushaf.Indopak16Line;
      final surahList =
          is16line ? surah16LinePageOffset : surah15LinePageOffset;

      int page = surahList[surahIndex];
      int paraIdx = paraForPage(page);
      final paraPageOffsets = paraPageOffsetsList();
      int paraStartPage = paraPageOffsets[paraIdx];
      int jumpToPage = page - paraStartPage;

      if ((_paraModel.currentPara - 1) != paraIdx) {
        _paraModel.setCurrentPara(paraIdx + 1, jumpToPage: jumpToPage + 1);
      } else {
        _pageController.jumpToPage(jumpToPage);
      }
    } catch (e) {
      showSnackBarMessage(context, error: true, "Error: $e");
    }
  }

  void _nextPage() {
    int? currentPageInPara = _pageController.page?.floor();
    int totalPages = pageCountForPara(_paraModel.currentPara - 1);
    int nextPage = (currentPageInPara ?? -1) + 1;
    if (nextPage >= totalPages) {
      _paraModel.setCurrentPara(_paraModel.currentPara + 1);
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    int? currentPageInPara = _pageController.page?.floor();
    int previousPage = (currentPageInPara ?? 1) - 1;
    if (previousPage < 0) {
      _paraModel.setCurrentPara(_paraModel.currentPara - 1, showLastPage: true);
    } else {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildDrawer() {
    return Builder(
      builder: (context) {
        final int currentParaIdx = _paraModel.currentPara - 1;
        final int currentPageInPara = (_pageController.page?.floor() ?? 0);
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
                          _paraModel.setCurrentPara(idx + 1);
                          Navigator.of(context).pop();
                        },
                      ),
                      SurahListView(
                        currentParaIdx: currentParaIdx,
                        currentPageInPara: currentPageInPara,
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
        int totalPages = pageCountForPara(_paraModel.currentPara - 1);
        _pageController.jumpToPage(totalPages - 1);
      },
      const SingleActivator(LogicalKeyboardKey.arrowLeft, control: true):
          () => _paraModel.setCurrentPara(_paraModel.currentPara + 1),
      const SingleActivator(LogicalKeyboardKey.arrowRight, control: true):
          () => _paraModel.setCurrentPara(_paraModel.currentPara - 1),
      const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true): () {
        int? currentPageInPara = _pageController.page?.floor();
        int currentPage =
            (currentPageInPara ?? 0) +
            paraPageOffsetsList()[_paraModel.currentPara - 1];
        int currentSurah = surahForPage(currentPage);
        _onSurahTapped(currentSurah == 113 ? 0 : currentSurah + 1, pop: false);
      },
      const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true): () {
        int? currentPageInPara = _pageController.page?.floor();
        int currentPage =
            (currentPageInPara ?? 0) +
            paraPageOffsetsList()[_paraModel.currentPara - 1];
        int currentSurah = surahForPage(currentPage);
        _onSurahTapped(currentSurah == 0 ? 113 : currentSurah - 1, pop: false);
      },
    };
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      floating: true,
      forceElevated: false,
      snap: true,
      pinned: false,
      actions: [
        IconButton(
          tooltip: "Next ${paraText()}",
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _paraModel.setCurrentPara(_paraModel.currentPara + 1);
          },
        ),
        IconButton(
          tooltip: "Previous ${paraText()}",
          icon: const Icon(Icons.arrow_forward),
          onPressed: () {
            _paraModel.setCurrentPara(_paraModel.currentPara - 1);
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Theme.of(context).brightness == Brightness.dark ? Colors.black : null,
      appBar: PreferredSize(
        preferredSize: const Size(double.infinity, 0),
        child: AppBar(bottom: null, shadowColor: Colors.transparent),
      ),
      body: FutureBuilder<void>(
        future: _load(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox.shrink();
          }
          return CallbackShortcuts(
            bindings: _shortcutBindings(),
            child: Focus(
              autofocus: true,
              child: CustomScrollView(
                controller: _scrollController,
                scrollBehavior:
                    const ScrollBehavior()..copyWith(overscroll: false),
                slivers: [
                  _buildAppBar(),
                  // The actual quran reading widget
                  ValueListenableBuilder<int>(
                    valueListenable: _paraModel.currentParaNotifier,
                    builder: (context, _, __) {
                      return ReadQuranWidget(
                        _paraModel,
                        pageController: _pageController,
                        verticalScrollResetFn: _resetVerticalScrollToZero,
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      drawer: _buildDrawer(),
    );
  }
}
