import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/models/routing.dart';
import 'package:quran_memorization_helper/widgets/read_quran.dart';

class ReadOnlyQuranPage extends StatelessWidget {
  final ReadOnlyQuranPageArgs args;

  const ReadOnlyQuranPage(this.args, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ReadQuranWidget(
        args.model,
        pageController: PageController(initialPage: args.page, keepPage: false),
        verticalScrollResetFn: () {},
        pageChangedCallback: (_) {},
      ),
    );
  }
}
