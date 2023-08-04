import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/pages/main_page.dart';
import 'package:quran_memorization_helper/utils/routing.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quran Revision Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        appBarTheme: AppBarTheme(
            elevation: 1,
            scrolledUnderElevation: 2,
            shadowColor: Theme.of(context).shadowColor),
      ),
      home: const MainPage(),
      onGenerateRoute: handleRoute,
    );
  }
}
