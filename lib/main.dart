import 'package:flutter/material.dart';
import 'package:quran_memorization_helper/pages/main_page.dart';
import 'package:quran_memorization_helper/utils/routing.dart';
import 'package:quran_memorization_helper/models/settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Settings.instance.readSettings();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Settings.instance,
      builder: (context, _) {
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
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            useMaterial3: true,
            colorSchemeSeed: Colors.blue,
            appBarTheme: AppBarTheme(
                elevation: 1,
                scrolledUnderElevation: 2,
                shadowColor: Theme.of(context).shadowColor),
          ),
          themeMode: Settings.instance.themeMode,
          home: const MainPage(),
          onGenerateRoute: handleRoute,
        );
      },
    );
  }
}
