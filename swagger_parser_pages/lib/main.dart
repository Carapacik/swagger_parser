import 'package:flutter/material.dart';
import 'package:swagger_parser_pages/app/app.dart';
import 'package:url_strategy/url_strategy.dart';

void main() {
  setPathUrlStrategy();
  runApp(const App());
}
