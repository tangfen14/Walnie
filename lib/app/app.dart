import 'package:baby_tracker/presentation/pages/home_page.dart';
import 'package:flutter/material.dart';

class BabyTrackerApp extends StatelessWidget {
  const BabyTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF0E8B72);

    return MaterialApp(
      title: 'Walnie',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        scaffoldBackgroundColor: const Color(0xFFF7FAF9),
        useMaterial3: true,
        fontFamily: 'PingFang SC',
      ),
      home: const HomePage(),
    );
  }
}
