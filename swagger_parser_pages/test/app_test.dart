@TestOn('browser')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/client_test.dart';
import 'package:swagger_parser_pages/app.dart';
import 'package:swagger_parser_pages/src/browser_generation.dart';
import 'package:web/web.dart' as web;

Finder _id(String id) => find.byComponentPredicate(
  (component) => component is DomComponent && component.id == id,
);

late Uri _fixtureRoot;
late String _workerUrl;
late String _referenceUrl;

void main() {
  setUpAll(() {
    // Keep the test server path before Jaspr changes browser history.
    _fixtureRoot = Uri.base.resolve('fixtures/');
    _workerUrl = Uri.base.resolve('../build/site/worker.dart.js').toString();
    _referenceUrl = Uri.base
        .resolve('../build/site/configuration.html')
        .toString();
  });
  for (final format in ['json', 'yaml']) {
    for (final serializer in [
      'plain',
      'json_serializable',
      'freezed',
      'dart_mappable',
    ]) {
      testClient(
        'loads $format files and archives optional fields with $serializer',
        (tester) async {
          tester.pumpComponent(App(workerUrl: _workerUrl));
          await tester.change(_id('serializer'), value: serializer);
          await tester.change(_id('root_api_class_name'), value: 'TransitApi');
          final String source = await _fixture('generation_schema.$format');
          await _selectFile(tester, 'schema-file', 'generation_schema.$format');
          await _waitFor(() => _schemaText(tester) == source);
          expect(source, contains('Станция Zürich 🚉'));
          expect(
            tester.findNode<web.HTMLInputElement>(_id('schema-file'))!.value,
            isEmpty,
          );
          await _click(tester, _id('generate'));
          await _waitFor(() => _id('generation-progress').evaluate().isEmpty);
          expect(_id('generation-error'), findsNothing);
          final Archive archive = await _archive(
            tester.findNode<web.HTMLAnchorElement>(_id('download-zip'))!.href,
          );
          final Map<String, String> files = {
            for (final file in archive.files)
              file.name: utf8.decode(file.content),
          };
          expect(files['transit_api.dart'], contains('class TransitApi'));
          expect(files['transit_api.dart'], contains("export 'exports.dart'"));
          expect(
            files['exports.dart'],
            contains('stations/models/station.dart'),
          );
          expect(
            files['default_client/api_client.dart'],
            contains('Future<Object?> getUnknown('),
          );
          final String model = files['stations/models/station.dart']!;
          expect(model, contains('final String? note'));
          expect(model, contains('/// Станция Zürich 🚉'));
          if (serializer == 'freezed') {
            expect(model, contains('required final String name'));
            expect(model, contains('required final String? platform'));
            expect(model, contains('final bool enabled = true'));
            expect(model, isNot(contains('required final String? note')));
          } else {
            expect(model, contains('required this.name'));
            expect(model, contains('required this.platform'));
            expect(model, contains('this.enabled = true'));
            expect(model, contains('this.note,'));
            expect(model, isNot(contains('required this.note')));
          }
          await _click(tester, _id('clear-schema'));
          expect(_schemaText(tester), isEmpty);
          expect(_id('download-zip'), findsNothing);
          expect(_id('schema-status'), findsNothing);
          expect(
            tester.findNode<web.HTMLSelectElement>(_id('serializer'))!.value,
            serializer,
          );
          // Selecting the same file again must trigger another read.
          await _selectFile(tester, 'schema-file', 'generation_schema.$format');
          await _waitFor(() => _schemaText(tester) == source);
        },
      );
    }
  }

  testClient('keeps input on cancelled selection and rejects invalid UTF-8', (
    tester,
  ) async {
    tester.pumpComponent(const App());
    final String before = _schemaText(tester);
    final web.HTMLInputElement input = tester.findNode<web.HTMLInputElement>(
      _id('schema-file'),
    )!;
    expect(input.accept, contains('.yml'));
    await tester.dispatchEvent(_id('schema-file'), web.Event('cancel'));
    await tester.dispatchEvent(_id('schema-file'), web.Event('change'));
    expect(_schemaText(tester), before);
    await _selectFile(tester, 'schema-file', 'invalid_utf8.json');
    await _waitFor(
      () => find.textContaining('Cannot read this file.').evaluate().isNotEmpty,
    );
    expect(_schemaText(tester), before);
    await _click(tester, _id('clear-schema'));
    expect(_schemaText(tester), isEmpty);
    expect(_id('schema-status'), findsNothing);
    await _selectFile(tester, 'schema-file', 'malformed_schema.yaml');
    await _waitFor(
      () => find
          .textContaining('Loaded malformed_schema.yaml.')
          .evaluate()
          .isNotEmpty,
    );
    await _click(tester, _id('check-schema'));
    expect(
      tester.findNode<web.Element>(_id('schema-status'))!.getAttribute('role'),
      'alert',
    );
  });

  testClient(
    'loads and clears template schemas without changing the generator',
    (tester) async {
      tester.pumpComponent(const App());
      final String generatorSchema = _schemaText(tester);
      await _click(tester, _id('tab-templates'));
      final String templates = tester
          .findNode<web.HTMLTextAreaElement>(_id('templates-source'))!
          .value;
      await _selectFile(
        tester,
        'templates-schema-file',
        'generation_schema.yaml',
      );
      await _waitFor(
        () => _schemaText(tester, 'templates-schema').contains('Станция'),
      );
      await _click(tester, _id('templates-clear-schema'));
      expect(_schemaText(tester, 'templates-schema'), isEmpty);
      expect(
        tester
            .findNode<web.HTMLTextAreaElement>(_id('templates-source'))!
            .value,
        templates,
      );
      await _click(tester, _id('tab-generator'));
      expect(_schemaText(tester), generatorSchema);
    },
  );

  testClient('keeps cleared input when a file read completes', (tester) async {
    tester.pumpComponent(const App());
    final web.File file = await _file('generation_schema.json');
    final web.HTMLInputElement input = tester.findNode<web.HTMLInputElement>(
      _id('schema-file'),
    )!;
    final transfer = web.DataTransfer();
    transfer.items.add(file);
    input
      ..files = transfer.files
      ..dispatchEvent(web.Event('change'));
    tester.findNode<web.HTMLButtonElement>(_id('clear-schema'))!.click();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(_schemaText(tester), isEmpty);
    expect(_id('schema-status'), findsNothing);
  });

  testClient('rejects uploaded external references without an archive', (
    tester,
  ) async {
    tester.pumpComponent(App(workerUrl: _workerUrl));
    await _selectFile(tester, 'schema-file', 'external_reference.yaml');
    await _waitFor(
      () => find
          .textContaining('Loaded external_reference.yaml.')
          .evaluate()
          .isNotEmpty,
    );
    await _click(tester, _id('generate'));
    await _waitFor(() => _id('generation-progress').evaluate().isEmpty);
    expect(_id('generation-error'), findsOneComponent);
    expect(_id('download-zip'), findsNothing);
    await _click(tester, _id('clear-schema'));
    expect(_id('generation-error'), findsNothing);
  });
  testClient('loads YAML into real form controls and retains other settings', (
    tester,
  ) async {
    tester.pumpComponent(const App());
    await _click(tester, _id('yaml-mode'));
    await tester.input(
      _id('yaml-config'),
      value: await _fixture('ui_config.yaml'),
    );
    await _click(tester, _id('form-mode'));
    expect(
      tester.findNode<web.HTMLSelectElement>(_id('http_client'))!.value,
      'dio',
    );
    expect(
      tester.findNode<web.HTMLSelectElement>(_id('serializer'))!.value,
      'freezed',
    );
    expect(
      tester.findNode<web.HTMLInputElement>(_id('root_api_class_name'))!.value,
      'TransitApi',
    );
    expect(
      tester.findNode<web.HTMLInputElement>(_id('generate_docs'))!.checked,
      isFalse,
    );
    await tester.change(_id('http_client'), value: 'http');
    await _click(tester, _id('yaml-mode'));
    final String yaml = tester
        .findNode<web.HTMLTextAreaElement>(_id('yaml-config'))!
        .value;
    expect(yaml, contains('http_client: http'));
    expect(yaml, contains('# Keep this setting.'));
    expect(yaml, contains("'#/components/schemas/Station'"));
  });

  testClient('keeps More options open when a checkbox changes', (tester) async {
    tester.pumpComponent(const App());
    tester
        .findNode<web.Element>(_id('more-options-toggle'))!
        .dispatchEvent(
          web.MouseEvent(
            'click',
            web.MouseEventInit(bubbles: true, cancelable: true),
          ),
        );
    await Future<void>.delayed(const Duration(milliseconds: 25));
    expect(
      tester.findNode<web.HTMLDetailsElement>(_id('more-options'))!.open,
      isTrue,
    );
    for (final id in [
      'use_presence_records',
      'generate_validators',
      'prune_unused_models',
    ]) {
      await tester.change(_id(id), checked: true);
      expect(
        tester.findNode<web.HTMLDetailsElement>(_id('more-options'))!.open,
        isTrue,
      );
    }
    await _click(tester, _id('yaml-mode'));
    await _click(tester, _id('form-mode'));
    expect(
      tester.findNode<web.HTMLDetailsElement>(_id('more-options'))!.open,
      isTrue,
    );
  });

  testClient('keeps invalid YAML visible and blocks the form transition', (
    tester,
  ) async {
    tester.pumpComponent(const App());
    await _click(tester, _id('yaml-mode'));
    await tester.input(
      _id('yaml-config'),
      value: await _fixture('invalid_serializer.yaml'),
    );
    await _click(tester, _id('form-mode'));
    expect(_id('config-error'), findsOneComponent);
    expect(_id('yaml-config'), findsOneComponent);
    expect(
      tester.findNode<web.HTMLTextAreaElement>(_id('yaml-config'))!.value,
      contains('invalid'),
    );
    await tester.input(
      _id('yaml-config'),
      value: await _fixture('corrected.json'),
    );
    await _click(tester, _id('form-mode'));
    expect(_id('config-error'), findsNothing);
    expect(
      tester.findNode<web.HTMLSelectElement>(_id('serializer'))!.value,
      'dart_mappable',
    );
  });

  testClient('checks schema input and restores the example after an error', (
    tester,
  ) async {
    tester.pumpComponent(const App());
    await _click(tester, _id('check-schema'));
    expect(find.textContaining('Schema parsed.'), findsOneComponent);
    await tester.input(
      _id('schema'),
      value: await _fixture('malformed_schema.yaml'),
    );
    await _click(tester, _id('check-schema'));
    expect(
      tester.findNode<web.Element>(_id('schema-status'))!.getAttribute('role'),
      'alert',
    );
    await _click(tester, _id('load-example'));
    expect(
      tester.findNode<web.HTMLTextAreaElement>(_id('schema'))!.value,
      contains('openapi: 3.2.1'),
    );
    await _click(tester, _id('check-schema'));
    expect(find.textContaining('Schema parsed.'), findsOneComponent);
  });
  testClient('shows progress then downloads a ZIP with the generated folders', (
    tester,
  ) async {
    tester.pumpComponent(App(workerUrl: _workerUrl));
    await tester.input(
      _id('schema'),
      value: await _fixture('generation_schema.yaml'),
    );
    await _click(tester, _id('yaml-mode'));
    await tester.input(
      _id('yaml-config'),
      value: await _fixture('generation.yaml'),
    );
    await _click(tester, _id('generate'));
    expect(_id('generation-progress'), findsOneComponent);
    expect(
      tester.findNode<web.HTMLButtonElement>(_id('generate'))!.disabled,
      isTrue,
    );
    await _waitFor(() => _id('generation-progress').evaluate().isEmpty);
    expect(_id('generation-error'), findsNothing);
    expect(_id('generation-success'), findsOneComponent);
    final web.HTMLAnchorElement link = tester.findNode<web.HTMLAnchorElement>(
      _id('download-zip'),
    )!;
    expect(link.download, 'swagger_parser.zip');
    final Archive archive = await _archive(link.href);
    expect(
      archive.files.map((f) => f.name),
      containsAll(['transit_api.dart', 'exports.dart']),
    );
    expect(
      archive.files.any(
        (f) => f.name.contains('/models/') && f.name.endsWith('.api.dart'),
      ),
      isTrue,
    );
    expect(
      tester.findNode<web.HTMLButtonElement>(_id('generate'))!.disabled,
      isFalse,
    );
  });

  testClient('cancels generation and recovers from schema errors', (
    tester,
  ) async {
    tester.pumpComponent(App(workerUrl: _workerUrl));
    await _click(tester, _id('generate'));
    await _click(tester, _id('cancel-generation'));
    await _waitFor(() => _id('generation-progress').evaluate().isEmpty);
    expect(find.textContaining('Generation cancelled.'), findsOneComponent);
    expect(_id('download-zip'), findsNothing);
    await tester.input(
      _id('schema'),
      value: await _fixture('malformed_schema.yaml'),
    );
    await _click(tester, _id('generate'));
    await _waitFor(() => _id('generation-progress').evaluate().isEmpty);
    expect(_id('generation-error'), findsOneComponent);
    expect(_id('download-zip'), findsNothing);
    await tester.input(
      _id('schema'),
      value: await _fixture('generation_schema.json'),
    );
    await _click(tester, _id('generate'));
    await _waitFor(() => _id('generation-progress').evaluate().isEmpty);
    expect(_id('generation-error'), findsNothing);
    expect(_id('download-zip'), findsOneComponent);
  });

  test('runs every serializer and client in the actual worker', () async {
    final generation = BrowserGeneration();
    final String schema = await _fixture('generation_schema.json');
    for (final serializer in [
      'plain',
      'json_serializable',
      'freezed',
      'dart_mappable',
    ]) {
      for (final client in ['retrofit', 'dio', 'http']) {
        final String config = jsonEncode({
          'generation': {'serializer': serializer, 'http_client': client},
        });
        final BrowserDownload download = await generation.run(
          schema,
          config,
          _workerUrl,
        );
        try {
          final Archive archive = await _archive(download.url);
          expect(
            archive.files.map((f) => f.name),
            containsAll(['api.dart', 'exports.dart']),
          );
          expect(archive.files.length, download.count);
        } finally {
          download.dispose();
        }
      }
    }
  });

  testClient(
    'keeps independent editors when switching tabs and opens local config',
    (tester) async {
      final String referenceUrl = _referenceUrl;
      tester.pumpComponent(
        App(workerUrl: _workerUrl, referenceUrl: referenceUrl),
      );
      await tester.input(
        _id('schema'),
        value: await _fixture('generation_schema.json'),
      );
      await tester.change(_id('root_api_class_name'), value: 'TransitApi');
      await _click(tester, _id('tab-templates'));
      expect(
        tester
            .findNode<web.HTMLInputElement>(
              _id('templates-root_api_class_name'),
            )!
            .value,
        'Api',
      );
      await tester.input(
        _id('templates-source'),
        value: await _fixture('templates/sources.yaml'),
      );
      await _click(tester, _id('tab-configuration'));
      final web.Element content = tester.findNode<web.Element>(
        _id('reference-content'),
      )!;
      await _waitFor(
        () => content.textContent?.contains('Complete defaults') ?? false,
      );
      expect(content.querySelector('#complete-defaults'), isNotNull);
      expect(content.textContent, contains('Api.api → ApiClient'));
      expect(web.document.querySelector('iframe'), isNull);
      await _click(tester, _id('tab-generator'));
      expect(
        tester
            .findNode<web.HTMLInputElement>(_id('root_api_class_name'))!
            .value,
        'TransitApi',
      );
      expect(
        tester.findNode<web.HTMLTextAreaElement>(_id('schema'))!.value,
        contains('"openapi"'),
      );
      await _click(tester, _id('tab-templates'));
      expect(
        tester
            .findNode<web.HTMLTextAreaElement>(_id('templates-source'))!
            .value,
        contains('Custom model output.'),
      );
      tester
          .findNode<web.Element>(_id('tab-templates'))!
          .dispatchEvent(
            web.KeyboardEvent(
              'keydown',
              web.KeyboardEventInit(key: 'Home', bubbles: true),
            ),
          );
      await Future<void>.delayed(const Duration(milliseconds: 25));
      expect(
        tester
            .findNode<web.Element>(_id('tab-generator'))!
            .getAttribute('aria-selected'),
        'true',
      );
    },
  );

  testClient(
    'downloads template overrides and helpers and reports template errors',
    (tester) async {
      tester.pumpComponent(App(workerUrl: _workerUrl));
      await _click(tester, _id('tab-templates'));
      await tester.input(
        _id('templates-source'),
        value: await _fixture('templates/sources.yaml'),
      );
      await _click(tester, _id('templates-generate'));
      await _waitFor(
        () => _id('templates-generation-progress').evaluate().isEmpty,
      );
      expect(_id('templates-generation-error'), findsNothing);
      final web.HTMLAnchorElement link = tester.findNode<web.HTMLAnchorElement>(
        _id('templates-download-zip'),
      )!;
      expect(link.download, 'swagger_parser_templates.zip');
      final Archive archive = await _archive(link.href);
      final Map<String, String> files = {
        for (final file in archive.files) file.name: utf8.decode(file.content),
      };
      expect(files['helpers/page.dart'], contains('class Page<T>'));
      expect(
        files['stations/stations_client.dart'],
        contains('class StationsClientRoutes'),
      );
      expect(files['exports.dart'], contains('helpers/page.dart'));
      await tester.input(
        _id('templates-source'),
        value: await _fixture('templates/invalid_mustache.yaml'),
      );
      await _click(tester, _id('templates-generate'));
      await _waitFor(
        () => _id('templates-generation-progress').evaluate().isEmpty,
      );
      expect(_id('templates-generation-error'), findsOneComponent);
      expect(_id('templates-download-zip'), findsNothing);
      await tester.input(
        _id('templates-source'),
        value: await _fixture('templates/sources.json'),
      );
      await _click(tester, _id('templates-generate'));
      await _waitFor(
        () => _id('templates-generation-progress').evaluate().isEmpty,
      );
      expect(_id('templates-generation-error'), findsNothing);
      expect(_id('templates-download-zip'), findsOneComponent);
    },
  );

  testClient('routes header links and logo with browser history', (
    tester,
  ) async {
    tester.pumpComponent(const App());
    expect(web.window.location.pathname, '/');
    expect(web.document.querySelectorAll('header [role=tab]').length, 3);
    expect(
      tester.findNode<web.HTMLAnchorElement>(_id('tab-templates'))!.href,
      endsWith('/template'),
    );
    await _click(tester, _id('tab-templates'));
    expect(web.window.location.pathname, '/template');
    await _click(tester, _id('tab-configuration'));
    expect(web.window.location.pathname, '/config');
    web.window.history.back();
    await _waitFor(
      () =>
          web.window.location.pathname == '/template' &&
          tester
                  .findNode<web.Element>(_id('tab-templates'))!
                  .getAttribute('aria-selected') ==
              'true',
    );
    web.window.history.forward();
    await _waitFor(
      () =>
          web.window.location.pathname == '/config' &&
          tester
                  .findNode<web.Element>(_id('tab-configuration'))!
                  .getAttribute('aria-selected') ==
              'true',
    );
    await _click(tester, _id('home-link'));
    expect(web.window.location.pathname, '/');
    expect(
      tester
          .findNode<web.Element>(_id('tab-generator'))!
          .getAttribute('aria-selected'),
      'true',
    );
    final web.Element github = web.document.querySelector('a.github-link')!;
    expect(
      github.getAttribute('href'),
      'https://github.com/Carapacik/swagger_parser',
    );
    expect(github.querySelector('img'), isNotNull);
  });

  testClient('selects a direct route under a hosting subpath', (tester) async {
    web.window.history.replaceState(null, '', '/swagger_parser/template/');
    tester.pumpComponent(const App(basePath: '/swagger_parser/'));
    expect(web.window.location.pathname, '/swagger_parser/template');
    expect(
      tester
          .findNode<web.Element>(_id('tab-templates'))!
          .getAttribute('aria-selected'),
      'true',
    );
    await _click(tester, _id('tab-configuration'));
    expect(web.window.location.pathname, '/swagger_parser/config');
    await _click(tester, _id('home-link'));
    expect(web.window.location.pathname, '/swagger_parser/');
  });

  test('reports worker load failures', () async {
    final generation = BrowserGeneration();
    await expectLater(
      generation.run(
        '',
        '{}',
        _fixtureRoot.resolve('missing-worker.js').toString(),
      ),
      throwsFormatException,
    );
  });
}

Future<String> _fixture(String name) async {
  final http.Response response = await http.get(_fixtureRoot.resolve(name));
  expect(response.statusCode, 200, reason: name);
  return utf8.decode(response.bodyBytes);
}

String _schemaText(ClientTester tester, [String id = 'schema']) =>
    tester.findNode<web.HTMLTextAreaElement>(_id(id))!.value;

Future<web.File> _file(String name) async {
  final http.Response response = await http.get(_fixtureRoot.resolve(name));
  expect(response.statusCode, 200);
  return web.File([response.bodyBytes.toJS].toJS, name);
}

Future<void> _selectFile(ClientTester tester, String id, String name) async {
  final web.HTMLInputElement input = tester.findNode<web.HTMLInputElement>(
    _id(id),
  )!;
  final transfer = web.DataTransfer();
  transfer.items.add(await _file(name));
  input.files = transfer.files;
  await tester.dispatchEvent(_id(id), web.Event('change'));
}

Future<void> _waitFor(bool Function() ready) async {
  final DateTime deadline = DateTime.now().add(const Duration(seconds: 40));
  while (!ready()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Generation did not finish.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
}

Future<Archive> _archive(String url) async {
  final web.Response response = await web.window.fetch(url.toJS).toDart;
  final JSArrayBuffer buffer = await response.arrayBuffer().toDart;
  return ZipDecoder().decodeBytes(buffer.toDart.asUint8List(), verify: true);
}

Future<void> _click(ClientTester tester, Finder finder) => tester.dispatchEvent(
  finder,
  web.MouseEvent('click', web.MouseEventInit(bubbles: true, cancelable: true)),
);
