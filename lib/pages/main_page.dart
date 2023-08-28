import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/models/ayat.dart';
import 'package:quran_memorization_helper/models/settings.dart';
import 'package:quran_memorization_helper/pages/page_constants.dart';
import 'package:quran_memorization_helper/models/quiz.dart';
import 'package:quran_memorization_helper/quran_data/ayat.dart';
import 'package:quran_memorization_helper/quran_data/pages.dart';
import 'package:quran_memorization_helper/quran_data/surahs.dart';
import 'package:quran_memorization_helper/widgets/read_quran.dart';
import 'package:flutter/services.dart' show rootBundle;

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final ParaAyatModel _paraModel = ParaAyatModel();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _paraListScrollController = ScrollController();
  final ScrollController _surahListScrollController = ScrollController();
  late final TabController _drawerTabController;

  @override
  void initState() {
    _drawerTabController = TabController(length: 2, vsync: this);
    _drawerTabController.addListener(_onDrawerTabChange);

    _paraModel.currentParaNotifier.addListener(scrollToTop);
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    _drawerTabController.removeListener(_onDrawerTabChange);
    _paraModel.currentParaNotifier.removeListener(scrollToTop);
    _paraModel.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0.0);
    }
  }

  void _onDrawerTabChange() {
    if (_drawerTabController.indexIsChanging) {
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
      return 48 * (currentParaIdx - 3);
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

  void scrollToPosition() {
    if (_scrollController.hasClients) {
      if (_paraModel.currentPara == Settings.instance.currentReadingPara) {
        _scrollController.jumpTo(Settings.instance.currentReadingScrollOffset);
      }
    } else {
      Future.delayed(const Duration(milliseconds: 20), scrollToPosition);
    }
  }

  Future<void> _load() async {
    await Settings.instance.readSettings();
    await _paraModel.readJsonDB();
    // If the para is same as what's in settings, then try to restore scroll position

    scrollToPosition();
    // remove before adding to ensure we don't listen twice
    _scrollController.removeListener(_saveScrollPosition);
    _scrollController.addListener(_saveScrollPosition);
  }

  void _saveScrollPosition() {
    Settings.instance.saveScrollPositionDelayed(
        _paraModel.currentPara, _scrollController.offset);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      await Settings.instance
          .saveScrollPosition(_paraModel.currentPara, _scrollController.offset);
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
    for (final a in _paraModel.ayahs) {
      a.ensureTextIsLoaded(data.buffer);
    }
    if (!mounted) return;
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
    return ValueListenableBuilder(
      valueListenable: _paraModel.currentParaNotifier,
      builder: (context, value, _) {
        return ListTile(
          minVerticalPadding: 0,
          visualDensity: VisualDensity.compact,
          title: Text("Para ${index + 1}"),
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
    double scrollOffset = jumpToPage * 785;
    scrollOffset += 50;

    if ((_paraModel.currentPara - 1) != paraIdx) {
      _paraModel.setCurrentPara(paraIdx + 1);
    }
    _scrollController.jumpTo(scrollOffset);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            slivers: [
              SliverAppBar(
                floating: true,
                forceElevated: true,
                // scrolledUnderElevation: v ? 2 : 1,
                snap: true,
                pinned: false,
                actions: [buildThreeDotMenu()],
              ),
              SliverToBoxAdapter(
                child: ValueListenableBuilder(
                  valueListenable: _paraModel.currentParaNotifier,
                  builder: (context, _, __) {
                    return ReadQuranWidget(_paraModel);
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _paraModel.setCurrentPara(_paraModel.currentPara + 1);
                  },
                  icon: const Icon(Icons.arrow_right),
                  label: const Text("Next Para"),
                ),
              ),
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
                Container(
                  height: 50,
                  color: Colors.black12,
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
                            title:
                                Text("${index + 1}. ${surahNameForIdx(index)}"),
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
