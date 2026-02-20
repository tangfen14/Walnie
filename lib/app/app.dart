import 'package:baby_tracker/presentation/pages/home_page.dart';
import 'package:baby_tracker/presentation/theme/walnie_theme.dart';
import 'package:flutter/material.dart';

class BabyTrackerApp extends StatelessWidget {
  const BabyTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Walnie',
      debugShowCheckedModeBanner: false,
      theme: buildWalnieLightTheme(),
      darkTheme: buildWalnieDarkTheme(),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}
