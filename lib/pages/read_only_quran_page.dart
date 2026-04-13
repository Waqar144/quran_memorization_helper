import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/models/routing.dart';
import 'package:quran_memorization_helper/models/settings.dart';
import 'package:quran_memorization_helper/widgets/read_quran.dart';
import 'package:quran_memorization_helper/widgets/my_orientation_build.dart';

class ReadOnlyQuranPage extends StatelessWidget {
  final ReadOnlyQuranPageArgs args;

  const ReadOnlyQuranPage(this.args, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomAppBar(
        padding: EdgeInsets.zero,
        height: kToolbarHeight,
        child: AppBar(),
      ),
      body: SafeArea(
        child: MyOrientationBuilder(
          builder: (context, orientation) {
            Settings.instance.temporaryState.dualPage =
                orientation == Orientation.landscape;
            return ReadQuranWidget(
              args.model,
              orientation: orientation,
              pageController: PageController(
                initialPage: args.page,
                keepPage: false,
              ),
              verticalScrollResetFn: () {},
              pageChangedCallback: (_) {},
            );
          },
        ),
      ),
    );
  }
}
