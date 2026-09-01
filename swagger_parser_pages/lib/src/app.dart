import 'package:flutter/material.dart';
import 'package:swagger_parser_pages/src/generator/generator_page.dart';

class const App({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Swagger Parser',
    restorationScopeId: 'swagger_parser',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorSchemeSeed: const Color(0xFFD0BCFF),
      brightness: Brightness.dark,
    ),
    home: const GeneratorPage(),
  );
}
