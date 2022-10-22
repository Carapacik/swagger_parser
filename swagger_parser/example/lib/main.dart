import 'package:flutter/material.dart';

// Run command:
// flutter pub run swagger_parser:generate

void main() {
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) => const MaterialApp(
        home: Scaffold(body: SizedBox.shrink()),
      );
}
