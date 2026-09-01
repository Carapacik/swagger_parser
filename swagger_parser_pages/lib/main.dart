import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:swagger_parser_pages/src/app.dart';

void main() {
  setUrlStrategy(PathUrlStrategy());
  runApp(const App());
}
