import 'package:jaspr/client.dart';
import 'package:swagger_parser_pages/app.dart';
import 'package:web/web.dart' as web;

/// Starts the browser editor.
void main() {
  Jaspr.initializeApp();
  final Uri base = Uri.parse(web.document.baseURI).resolve('.');
  runApp(
    App(
      basePath: base.path,
      workerUrl: base.resolve('worker.dart.js').toString(),
      referenceUrl: base.resolve('configuration.html').toString(),
    ),
    attachTo: '#app',
  );
}
