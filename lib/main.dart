// lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'game_page.dart';
import 'score_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ReactToTapApp());
}

class ReactToTapApp extends StatelessWidget {
  const ReactToTapApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseText = GoogleFonts.poppinsTextTheme().apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    );

    return MaterialApp(
      title: 'React To Tap',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF7C4DFF), // Purple indie vibe
        brightness: Brightness.light,
        textTheme: baseText,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF7C4DFF),
        brightness: Brightness.dark,
        textTheme: baseText,
      ),
      initialRoute: GamePage.route,
      routes: {
        GamePage.route: (_) => const GamePage(),
        ScorePage.route: (_) => const ScorePage(),
      },
      // Smooth fade transitions
      onGenerateRoute: (settings) {
        WidgetBuilder? builder = {
          GamePage.route: (_) => const GamePage(),
          ScorePage.route: (_) => const ScorePage(),
        }[settings.name];

        if (builder == null) return null;

        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 220),
        );
      },
    );
  }
}
