import 'package:flutter/material.dart';
import 'package:swagger_parser_pages/content/main_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Swagger Parser',
    restorationScopeId: 'swagger parser',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorSchemeSeed: const Color(0xFFD0BCFF),
      brightness: Brightness.dark,
    ),
    themeMode: ThemeMode.dark,
    home: const MainPage(),
  );
}
