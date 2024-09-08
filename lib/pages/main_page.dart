import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/models/ayat.dart';
import 'package:quran_memorization_helper/models/settings.dart';
import 'package:quran_memorization_helper/pages/page_constants.dart';
import 'package:quran_memorization_helper/models/quiz.dart';
import 'package:quran_memorization_helper/quran_data/ayat.dart';
import 'package:quran_memorization_helper/quran_data/pages.dart';
import 'package:quran_memorization_helper/widgets/read_quran.dart';
import 'package:quran_memorization_helper/widgets/surah_list_view.dart';
import 'package:quran_memorization_helper/widgets/para_list_view.dart';
import 'package:quran_memorization_helper/utils/utils.dart';
import 'package:flutter/services.dart'
    show HardwareKeyboard, KeyDownEvent, LogicalKeyboardKey, rootBundle;

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

  @override
  void initState() {
    _paraModel = ParaAyatModel(onParaChanged);
    _drawerTabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    _paraModel.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void onParaChanged(int para, bool showLastPage, int jumpToPage) {
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
      onParaChanged(_paraModel.currentPara, false, jumpToPage);
    } else {
      if (mounted) showSnackBarMessage(context, error: true, "Error: $error");
    }
  }

  void _saveScrollPosition() {
    // multiply by 500 to make the offset bigger so it can be saved, otherwise it gets ignored
    // as the difference between last save value and this one might be too small
    Settings.instance.saveScrollPositionDelayed(
        _paraModel.currentPara, _pageController.page?.floor() ?? 0);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      await Settings.instance.saveScrollPosition(
          _paraModel.currentPara, _pageController.page?.floor() ?? 0);
    }
  }

  void _openQuizParaSelectionPage() async {
    final quizCreationArgs = await Navigator.of(context)
        .pushNamed(quizSelectionPage) as QuizCreationArgs?;
    if (!mounted) return;
    if (quizCreationArgs == null) return;
    if (quizCreationArgs.selectedParas.isEmpty) return;
    final ayahsToAdd = await Navigator.of(context).pushNamed(quizPage,
        arguments: quizCreationArgs) as Map<int, List<Ayat>>?;
    if (!mounted) return;
    if (ayahsToAdd == null || ayahsToAdd.isEmpty) return;
    _paraModel.merge(ayahsToAdd);
  }

  void _openSettings() async {
    await Navigator.pushNamed(context, settingsPageRoute,
        arguments: _paraModel);
  }

  void _openMutashabihas() {
    Navigator.pushNamed(context, mutashabihasPage, arguments: _paraModel);
  }

  void _openMarkedAyahsPage() async {
    final data = await rootBundle.load("assets/quran.txt");
    final List<Mutashabiha> mutashabihat =
        await importParaMutashabihas(_paraModel.currentPara - 1, data.buffer);
    final ayahAndMutashabihas =
        _paraModel.ayahsAndMutashabihasList(mutashabihat);
    for (final a in ayahAndMutashabihas) {
      a.ensureTextIsLoaded(data.buffer);
    }
    if (!mounted) return;
    Navigator.pushNamed(context, markedAyahsPage, arguments: {
      'model': _paraModel,
      'ayahAndMutashabihas': ayahAndMutashabihas
    });
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
        final actionCallback = actions[value];
        if (actionCallback == null) throw "Unknown action: $value";
        actionCallback();
      },
      icon: const Icon(Icons.more_vert),
      itemBuilder: (BuildContext context) {
        return actions.keys.map((String choice) {
          return PopupMenuItem<String>(
            value: choice,
            child: Text(choice),
          );
        }).toList();
      },
    );
  }

  void _onSurahTapped(int surahIndex) {
    Navigator.of(context).pop();
    if (surahIndex < 0 || surahIndex > 113) {
      return;
    }
    int page = surah16LinePageOffset[surahIndex];
    int paraIdx = paraForPage(page);
    int paraStartPage = para16LinePageOffsets[paraIdx];
    int jumpToPage = page - paraStartPage;

    if ((_paraModel.currentPara - 1) != paraIdx) {
      _paraModel.setCurrentPara(paraIdx + 1, jumpToPage: jumpToPage + 1);
    } else {
      _pageController.jumpToPage(jumpToPage);
    }
  }

  final FocusNode _focusNode = FocusNode();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Theme.of(context).brightness == Brightness.dark ? Colors.black : null,
      appBar: PreferredSize(
        preferredSize: const Size(double.infinity, 0),
        child: AppBar(bottom: null, shadowColor: Colors.transparent),
      ),
      body: FutureBuilder(
        future: _load(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox.shrink();
          }
          return KeyboardListener(
              focusNode: _focusNode,
              autofocus: true,
              onKeyEvent: (event) {
                bool isCtrlPressed =
                    HardwareKeyboard.instance.isControlPressed ||
                        HardwareKeyboard.instance.isMetaPressed;
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                  int totalPages = pageCountForPara(_paraModel.currentPara - 1);
                  int nextPage = (_pageController.page?.floor() ?? -1) + 1;
                  if (nextPage >= totalPages || isCtrlPressed) {
                    _paraModel.setCurrentPara(_paraModel.currentPara + 1);
                  } else {
                    _pageController.nextPage(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut);
                  }
                } else if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.arrowRight) {
                  int previousPage = (_pageController.page?.floor() ?? 1) - 1;
                  if (previousPage <= 0 || isCtrlPressed) {
                    _paraModel.setCurrentPara(_paraModel.currentPara - 1,
                        showLastPage: !isCtrlPressed);
                  } else {
                    _pageController.previousPage(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut);
                  }
                }
              },
              child: CustomScrollView(
                controller: _scrollController,
                scrollBehavior: const ScrollBehavior()
                  ..copyWith(overscroll: false),
                slivers: [
                  SliverAppBar(
                    floating: true,
                    forceElevated: true,
                    // scrolledUnderElevation: v ? 2 : 1,
                    snap: true,
                    pinned: false,
                    actions: [
                      IconButton(
                        tooltip: "Next Para",
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          _paraModel.setCurrentPara(_paraModel.currentPara + 1);
                        },
                      ),
                      IconButton(
                        tooltip: "Previous Para",
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () {
                          _paraModel.setCurrentPara(_paraModel.currentPara - 1);
                        },
                      ),
                      buildThreeDotMenu()
                    ],
                  ),
                  ValueListenableBuilder(
                    valueListenable: _paraModel.currentParaNotifier,
                    builder: (context, _, __) {
                      return ReadQuranWidget(
                        _paraModel,
                        pageController: _pageController,
                      );
                    },
                  ),
                  IconButton(
                    onPressed: () {
                      Settings.instance.themeMode =
                          Settings.instance.themeMode == ThemeMode.light
                              ? ThemeMode.dark
                              : ThemeMode.light;
                    },
                    icon: Icon(Settings.instance.themeMode == ThemeMode.light
                        ? Icons.mode_night
                        : Icons.sunny),
                    tooltip: Settings.instance.themeMode == ThemeMode.light
                        ? "Switch to night mode"
                        : "Switch to light mode",
                  ),
                  buildThreeDotMenu()
                ],
              ));
        },
      ),
      drawer: Builder(builder: (context) {
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
                    tabs: const [
                      Tab(text: "Para"),
                      Tab(text: "Surah"),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _drawerTabController,
                    children: [
                      ParaListView(
                        model: _paraModel,
                        currentParaIdx: currentParaIdx,
                        onParaTapped: (idx) {
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
      }),
    );
  }
}
