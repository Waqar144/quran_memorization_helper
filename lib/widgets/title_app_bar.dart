import 'package:flutter/material.dart';

class TitleOnlyAppBar extends AppBar {
  TitleOnlyAppBar(String titleText, {super.key})
    : super(
        title: Text(titleText, style: TextStyle(fontSize: 18)),
        leadingWidth: 0,
        leading: const SizedBox.shrink(),
      );
}
