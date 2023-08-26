import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/models/ayat.dart';
import 'package:quran_memorization_helper/models/settings.dart';
import 'package:quran_memorization_helper/pages/page_constants.dart';
import 'package:quran_memorization_helper/models/quiz.dart';
import 'package:quran_memorization_helper/quran_data/ayat.dart';
import 'package:quran_memorization_helper/widgets/read_quran.dart';
import 'package:flutter/services.dart' show rootBundle;

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final ParaAyatModel _paraModel = ParaAyatModel();
  bool loaded = false;

  @override
  void initState() {
    Settings.instance.readSettings();
    _paraModel.readJsonDB().then((v) {
      loaded = true;
      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    _paraModel.dispose();
    super.dispose();
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

  Widget paraListItem(int index, double size) {
    return SizedBox(
      width: size,
      child: ValueListenableBuilder(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size(double.infinity, 0),
        child: AppBar(bottom: null, shadowColor: Colors.transparent),
      ),
      body: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (ctx, v) => [
          SliverAppBar(
            floating: true,
            forceElevated: true,
            scrolledUnderElevation: v ? 2 : 1,
            snap: true,
            pinned: false,
            actions: [buildThreeDotMenu()],
          ),
        ],
        body: loaded == false
            ? const SizedBox.shrink()
            : ValueListenableBuilder(
                valueListenable: _paraModel.currentParaNotifier,
                builder: (context, _, __) {
                  return ReadQuranWidget(_paraModel);
                },
              ),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Wrap(
            alignment: WrapAlignment.start,
            direction: Axis.vertical,
            children: List.generate(30, (i) => i).map((index) {
              return paraListItem(index, 120);
            }).toList(),
          ),
        ),
      ),
    );
  }
}
