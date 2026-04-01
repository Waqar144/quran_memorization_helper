import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/widgets/read_quran.dart';
import 'package:quran_memorization_helper/models/ayat.dart';

class ReadOnlyQuranPage extends StatelessWidget {
  final ParaAyatModel _model;
  final int page;

  const ReadOnlyQuranPage(this._model, this.page, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ReadQuranWidget(
        _model,
        pageController: PageController(initialPage: page, keepPage: false),
        verticalScrollResetFn: () {},
        pageChangedCallback: (_) {},
      ),
    );
  }
}
