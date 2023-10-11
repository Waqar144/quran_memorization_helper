import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/models/ayat.dart';
import 'package:quran_memorization_helper/models/settings.dart';
import 'package:quran_memorization_helper/pages/page_constants.dart';
import 'package:quran_memorization_helper/models/quiz.dart';
import 'package:quran_memorization_helper/quran_data/ayat.dart';
import 'package:quran_memorization_helper/quran_data/pages.dart';
import 'package:quran_memorization_helper/quran_data/para_bounds.dart';
import 'package:quran_memorization_helper/quran_data/surahs.dart';
import 'package:quran_memorization_helper/widgets/read_quran.dart';
import 'package:quran_memorization_helper/utils/utils.dart';
import 'package:flutter/services.dart' show rootBundle;

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late final ParaAyatModel _paraModel;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _paraListScrollController = ScrollController();
  final ScrollController _surahListScrollController = ScrollController();
  late final TabController _drawerTabController;
  PageController _pageController = PageController(keepPage: false);

  @override
  void initState() {
    _paraModel = ParaAyatModel(onParaChanged);
    _drawerTabController = TabController(length: 2, vsync: this);
    _drawerTabController.addListener(_onDrawerTabChange);

    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    _drawerTabController.removeListener(_onDrawerTabChange);
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

  void _onDrawerTabChange() {
    if (!_drawerTabController.indexIsChanging) {
      //listen to false so we handle both drag and tap
      if (_drawerTabController.index == 0) {
        _scrollToParaInDrawer();
      } else if (_drawerTabController.index == 1) {
        _scrollToPosition(_surahListScrollController, () {
          int surah = firstSurahInPara(_paraModel.currentPara - 1);
          return 48 * surah.toDouble();
        });
      }
    }
  }

  void _scrollToParaInDrawer() {
    _scrollToPosition(_paraListScrollController, () {
      int currentParaIdx = _paraModel.currentPara - 1;
      return currentParaIdx > 8 ? 48 * (currentParaIdx - 3) : 0;
    });
  }

  static void _scrollToPosition(
      ScrollController controller, double Function() getJumpPos) {
    if (controller.hasClients) {
      double jump = getJumpPos();
      if (jump > controller.position.maxScrollExtent) {
        jump = controller.position.maxScrollExtent;
      }
      controller.jumpTo(jump);
    } else {
      Future.delayed(const Duration(milliseconds: 10),
          () => _scrollToPosition(controller, getJumpPos));
    }
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

  Widget paraListItem(int index) {
    int count = _paraModel.markedAyahCountForPara(index);
    return ValueListenableBuilder(
      valueListenable: _paraModel.currentParaNotifier,
      builder: (context, value, _) {
        return ListTile(
          minVerticalPadding: 0,
          visualDensity: VisualDensity.compact,
          title: Text(
            getParaNameForIndex(index),
            style: const TextStyle(
              letterSpacing: 0,
              fontSize: 24,
              fontFamily: 'Al Mushaf',
            ),
          ),
          leading: Text(
            "${index + 1}.",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20),
          ),
          trailing: Text(
            count > 0 ? "$count" : "",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.red),
          ),
          onTap: () {
            _paraModel.setCurrentPara(index + 1);
            Navigator.of(context).pop();
          },
          selected: value == (index + 1),
          selectedTileColor: Theme.of(context).highlightColor,
        );
      },
    );
  }

  void _onSurahTapped(int surahIndex) {
    Navigator.of(context).pop();
    if (surahIndex < 0 || surahIndex > 113) {
      return;
    }
    int page = surah16LinePageOffset[surahIndex] - 1;
    int paraIdx = paraForPage(page);
    int paraStartPage = para16LinePageOffsets[paraIdx];
    int jumpToPage = page - paraStartPage;

    if ((_paraModel.currentPara - 1) != paraIdx) {
      _paraModel.setCurrentPara(paraIdx + 1, jumpToPage: jumpToPage + 1);
    } else {
      _pageController.jumpToPage(jumpToPage);
    }
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
      body: FutureBuilder(
        future: _load(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox.shrink();
          }
          return CustomScrollView(
            controller: _scrollController,
            scrollBehavior: const ScrollBehavior()..copyWith(overscroll: false),
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
              )
            ],
          );
        },
      ),
      drawer: Drawer(
        child: SafeArea(
          child: DefaultTabController(
            animationDuration: const Duration(milliseconds: 150),
            length: 2,
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
                      ListView.builder(
                        controller: _paraListScrollController,
                        scrollDirection: Axis.vertical,
                        itemCount: 30,
                        itemExtent: 48,
                        itemBuilder: (context, index) {
                          return paraListItem(index);
                        },
                      ),
                      ListView.builder(
                        controller: _surahListScrollController,
                        scrollDirection: Axis.vertical,
                        itemCount: 114,
                        itemExtent: 48,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: Text(
                              "${index + 1}.",
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 20),
                            ),
                            title: Text(
                              surahDataForIdx(index, arabic: true).name,
                              style: const TextStyle(
                                letterSpacing: 0,
                                fontSize: 24,
                                fontFamily: 'Al Mushaf',
                              ),
                            ),
                            onTap: () => _onSurahTapped(index),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      onDrawerChanged: (opened) {
        if (!opened) return;
        if (_drawerTabController.index != 0) {
          _drawerTabController.animateTo(0);
        } else {
          _scrollToParaInDrawer();
        }
      },
    );
  }
}
