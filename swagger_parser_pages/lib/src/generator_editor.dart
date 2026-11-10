import 'dart:convert';
import 'dart:js_interop';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:swagger_parser/swagger_parser.dart';
import 'package:swagger_parser_pages/src/browser_generation.dart';
import 'package:swagger_parser_pages/src/editor_config.dart';
import 'package:swagger_parser_pages/src/editor_services.dart';
import 'package:swagger_parser_pages/src/example_schema.dart';
import 'package:swagger_parser_pages/src/template_input.dart';
import 'package:web/web.dart' as web;
import 'package:yaml/yaml.dart';

/// Schema and config editor for one independent generation workspace.
class const GeneratorEditor({
  super.key,

  /// Worker script URL, relative to the current page by default.
  final String workerUrl = 'worker.dart.js',

  /// Enables in-memory Mustache templates.
  final bool templates = false,
}) extends StatefulComponent {
  /// Creates the Pages preview.
  this;

  @override
  State<GeneratorEditor> createState() => _GeneratorEditorState();
}

class _GeneratorEditorState() extends State<GeneratorEditor> {
  final EditorServices _services = EditorServices();
  EditorConfig _config = EditorConfig.defaults();
  String _schema = exampleSchema;
  String _yamlDraft = '';
  String? _configError;
  String? _schemaMessage;
  bool _schemaError = false;
  bool _showYaml = false;
  bool _moreOptionsOpen = false;
  int _schemaRevision = 0;
  int _fileReadRevision = 0;
  bool _loadingSchema = false;
  final BrowserGeneration _generation = BrowserGeneration();
  BrowserDownload? _download;
  bool _generating = false;
  String? _generationError;
  String _templateSource = exampleTemplates;

  String _id(String name) => component.templates ? 'templates-$name' : name;

  void _replaceSchema(String source, {String? message}) {
    _fileReadRevision++;
    _download?.dispose();
    setState(() {
      _schema = source;
      _schemaRevision++;
      _loadingSchema = false;
      _schemaMessage = message;
      _schemaError = false;
      _generationError = null;
      _download = null;
    });
  }

  Future<void> _loadSchema(web.Event event) async {
    final input = event.target! as web.HTMLInputElement;
    final web.File? file = input.files?.item(0);
    input.value = '';
    if (file == null) {
      return;
    }
    final int revision = ++_fileReadRevision;
    setState(() {
      _loadingSchema = true;
      _schemaMessage = 'Reading schema…';
      _schemaError = false;
    });
    try {
      final JSArrayBuffer buffer = await file.arrayBuffer().toDart;
      final String source = utf8.decode(buffer.toDart.asUint8List());
      if (!mounted || revision != _fileReadRevision) {
        return;
      }
      _replaceSchema(source, message: 'Loaded ${file.name}.');
    } on Object {
      if (!mounted || revision != _fileReadRevision) {
        return;
      }
      setState(() {
        _loadingSchema = false;
        _schemaMessage = 'Cannot read this file. Use UTF-8 JSON or YAML.';
        _schemaError = true;
      });
    }
  }

  Future<void> _generate() async {
    if (_generating || _loadingSchema || (_showYaml && !_applyYaml())) {
      return;
    }
    _download?.dispose();
    setState(() {
      _download = null;
      _generationError = null;
      _generating = true;
    });
    try {
      final BrowserDownload result = await _generation.run(
        _schema,
        _config.yaml,
        component.workerUrl,
        templates: component.templates ? _templateSource : null,
      );
      if (!mounted) {
        result.dispose();
        return;
      }
      setState(() => _download = result);
      result.save();
    } on Object catch (error) {
      if (mounted) {
        setState(
          () => _generationError = error is FormatException
              ? error.message
              : error.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _generating = false);
      }
    }
  }

  @override
  void dispose() {
    _generation.cancel();
    _download?.dispose();
    super.dispose();
  }

  void _setOption(String key, Object value) {
    try {
      final EditorConfig next = _config.withValue(key, value);
      setState(() {
        _config = next;
        _configError = null;
      });
    } on FormatException catch (error) {
      setState(() => _configError = error.message);
    }
  }

  bool _applyYaml() {
    try {
      final next = EditorConfig.parse(_yamlDraft);
      setState(() {
        _config = next;
        _configError = null;
        _schemaMessage = null;
      });
      return true;
    } on YamlException catch (error) {
      setState(() => _configError = error.message);
    } on FormatException catch (error) {
      setState(() => _configError = error.message);
    }
    return false;
  }

  void _selectMode(bool yaml) {
    if (_showYaml == yaml) {
      return;
    }
    if (!yaml && !_applyYaml()) {
      return;
    }
    setState(() {
      _showYaml = yaml;
      if (yaml) {
        _yamlDraft = _config.yaml;
      }
    });
  }

  void _checkSchema() {
    if (_showYaml && !_applyYaml()) {
      return;
    }
    try {
      final OpenApiDocument document = _services.parse(
        _schema,
        _config.parseConfig,
      );
      final String title = switch (document) {
        SwaggerV2Document(:final info) => info.title,
        OpenApiV30Document(:final info) => info.title,
        OpenApiV31Document(:final info) => info.title,
        OpenApiV32Document(:final info) => info.title,
      };
      setState(() {
        _schemaMessage = '$title · ${document.version.value} · Schema parsed.';
        _schemaError = false;
      });
    } on OpenApiException catch (error) {
      setState(() {
        _schemaMessage =
            '${error.message}'
            '${error.location == null ? '' : ' (${error.location!.line}:${error.location!.column})'}';
        _schemaError = true;
      });
    }
  }

  @override
  Component build(BuildContext context) => div(classes: 'editor-view', [
    main_([
      section(classes: 'hero', [
        div([
          const p(classes: 'eyebrow', [
            span(classes: 'status-dot', []),
            Component.text('OPENAPI → DART'),
          ]),
          h1([
            Component.text(
              component.templates ? 'Your templates.' : 'Your schema.',
            ),
            const br(),
            const span([Component.text('Your Dart API.')]),
          ]),
          p(classes: 'hero-copy', [
            Component.text(
              component.templates
                  ? 'Customize Dart output with swagger_parser_templates. Replace files or add helpers with Mustache.'
                  : 'Turn OpenAPI into Dart models and HTTP clients. Start with a schema. Choose the code that fits your app.',
            ),
          ]),
          const div(classes: 'compatibility', [
            span([Component.text('Swagger 2.0')]),
            span([Component.text('OpenAPI 3.0 · 3.1 · 3.2')]),
            span([Component.text('JSON + YAML')]),
          ]),
        ]),
        div(classes: 'workflow', [
          _step('01', 'Bring your schema', 'Paste or load JSON or YAML.'),
          _step('02', 'Make it yours', 'Choose a client and serializer.'),
          _step(
            '03',
            'Take your code',
            'Download your generated files as ZIP.',
          ),
        ]),
      ]),
      section(
        classes: 'workspace-section',
        attributes: const {'aria-label': 'Schema workspace'},
        [
          const div(classes: 'workspace-heading', [
            div([
              h2([Component.text('Build your API')]),
              p([Component.text('Your schema stays in this browser tab.')]),
            ]),
            span(classes: 'preview-badge', [
              Component.text('LOCAL GENERATION'),
            ]),
          ]),
          if (component.templates) _templateEditor(),
          div(classes: 'workspace', [
            section(classes: 'schema-panel panel', [
              div(classes: 'panel-heading', [
                label(htmlFor: _id('schema'), const [
                  span(classes: 'step-label', [Component.text('01')]),
                  Component.text('OpenAPI schema'),
                ]),
                button(
                  id: _id('load-example'),
                  classes: 'quiet-button',
                  disabled: _generating,
                  onClick: () => _replaceSchema(exampleSchema),
                  const [Component.text('Load example')],
                ),
              ]),
              div(classes: 'editor-bar schema-tools', [
                input(
                  id: _id('schema-file'),
                  type: InputType.file,
                  attributes: const {
                    'accept': '.json,.yaml,.yml,application/json,application/yaml,text/yaml',
                    'hidden': '',
                    'aria-label': 'Load schema file',
                  },
                  events: {'change': _loadSchema},
                ),
                button(
                  id: _id('load-schema'),
                  classes: 'quiet-button',
                  disabled: _generating,
                  onClick: () =>
                      (web.document.getElementById(_id('schema-file'))!
                              as web.HTMLInputElement)
                          .click(),
                  const [Component.text('Load file')],
                ),
                button(
                  id: _id('clear-schema'),
                  classes: 'quiet-button',
                  disabled: _generating,
                  onClick: () => _replaceSchema(''),
                  const [Component.text('Clear')],
                ),
                const span([Component.text('JSON / YAML')]),
              ]),
              textarea(
                key: ValueKey(_schemaRevision),
                id: _id('schema'),
                classes: 'code-editor schema-editor',
                spellCheck: SpellCheck.isFalse,
                attributes: {
                  'aria-describedby': _id('schema-help'),
                  'autocapitalize': 'off',
                },
                onInput: (value) {
                  _fileReadRevision++;
                  _schema = value;
                  if (_schemaMessage != null || _loadingSchema) {
                    setState(() {
                      _schemaMessage = null;
                      _loadingSchema = false;
                    });
                  }
                },
                [Component.text(_schema)],
              ),
              div(classes: 'editor-footer', [
                p(id: _id('schema-help'), const [
                  Component.text(
                    'Paste or load one schema. External references are not supported.',
                  ),
                ]),
                button(
                  id: _id('check-schema'),
                  classes: 'quiet-button',
                  disabled: _loadingSchema,
                  onClick: _checkSchema,
                  const [
                    Component.text('Check schema'),
                    span([Component.text('→')]),
                  ],
                ),
              ]),
              div(classes: 'generation-actions', [
                button(
                  id: _id('generate'),
                  classes: 'primary-button',
                  disabled: _generating || _loadingSchema,
                  onClick: _generate,
                  [
                    if (_generating) const span(classes: 'spinner', []),
                    Component.text(
                      _generating ? 'Generating…' : 'Generate ZIP',
                    ),
                  ],
                ),
                if (_generating)
                  button(
                    id: _id('cancel-generation'),
                    classes: 'quiet-button',
                    onClick: _generation.cancel,
                    const [Component.text('Cancel')],
                  ),
              ]),
              if (_generating)
                div(
                  id: _id('generation-progress'),
                  classes: 'notice',
                  attributes: const {'role': 'status', 'aria-live': 'polite'},
                  const [Component.text('Generating files and preparing ZIP…')],
                ),
              if (_generationError case final error?)
                div(
                  id: _id('generation-error'),
                  classes: 'notice error',
                  attributes: const {'role': 'alert'},
                  [Component.text(error)],
                ),
              if (_download case final download?) ...[
                div(
                  id: _id('generation-success'),
                  classes: 'notice success',
                  attributes: const {'role': 'status'},
                  [
                    Component.text('${download.count} files ready. '),
                    a(
                      id: _id('download-zip'),
                      href: download.url,
                      attributes: {'download': download.name},
                      const [Component.text('Download ZIP again')],
                    ),
                  ],
                ),
                if (download.diagnostics.isNotEmpty)
                  pre(classes: 'notice diagnostics', [
                    Component.text(download.diagnostics),
                  ]),
              ],
              if (_schemaMessage case final message?)
                div(
                  id: _id('schema-status'),
                  classes: 'notice ${_schemaError ? 'error' : 'success'}',
                  attributes: {'role': _schemaError ? 'alert' : 'status'},
                  [Component.text(message)],
                ),
            ]),
            aside(classes: 'config-panel panel', [
              const div(classes: 'panel-heading', [
                h2([
                  span(classes: 'step-label', [Component.text('02')]),
                  Component.text('Configuration'),
                ]),
              ]),
              div(classes: 'config-body', [
                div(
                  classes: 'mode-switch',
                  attributes: const {
                    'role': 'group',
                    'aria-label': 'Configuration editor',
                  },
                  [
                    button(
                      id: _id('form-mode'),
                      classes: _showYaml ? '' : 'selected',
                      attributes: {'aria-pressed': '${!_showYaml}'},
                      onClick: () => _selectMode(false),
                      const [Component.text('Form')],
                    ),
                    button(
                      id: _id('yaml-mode'),
                      classes: _showYaml ? 'selected' : '',
                      attributes: {'aria-pressed': '$_showYaml'},
                      onClick: () => _selectMode(true),
                      const [Component.text('YAML')],
                    ),
                  ],
                ),
                if (_showYaml) ...[
                  label(
                    htmlFor: _id('yaml-config'),
                    classes: 'field-label',
                    const [Component.text('Paste your config')],
                  ),
                  const p(classes: 'field-help', [
                    Component.text(
                      'Use a swagger_parser section or a bare config. The pasted schema replaces the input path.',
                    ),
                  ]),
                  textarea(
                    id: _id('yaml-config'),
                    classes: 'code-editor config-editor',
                    spellCheck: SpellCheck.isFalse,
                    attributes: const {'autocapitalize': 'off'},
                    onInput: (value) => _yamlDraft = value,
                    [Component.text(_yamlDraft)],
                  ),
                  button(
                    id: _id('apply-config'),
                    classes: 'secondary-button',
                    onClick: _applyYaml,
                    const [Component.text('Apply YAML')],
                  ),
                ] else ...[
                  _select('http_client', 'HTTP client', {
                    'retrofit': 'Retrofit + Dio',
                    'dio': 'Dio',
                    'http': 'package:http',
                  }),
                  _select('serializer', 'Serialization', {
                    'plain': 'Plain fromJson / toJson',
                    'json_serializable': 'json_serializable',
                    'freezed': 'Freezed + json_serializable',
                    'dart_mappable': 'dart_mappable',
                  }),
                  _select('response_mode', 'Responses', {
                    'first_success': 'First success',
                    'all_statuses': 'All declared statuses',
                  }),
                  _select('unmatched_union_values', 'Unmatched union values', {
                    'reject': 'Reject',
                    'preserve': 'Preserve JSON',
                  }),
                  div(classes: 'field-row', [
                    _input('root_api_class_name', 'API class'),
                    _input('page_width', 'Line width', numeric: true),
                  ]),
                  _toggle('generate_docs', 'Generate Dartdoc'),
                  details(
                    id: _id('more-options'),
                    classes: 'advanced',
                    open: _moreOptionsOpen,
                    events: {
                      'toggle': (event) {
                        _moreOptionsOpen =
                            (event.target! as web.HTMLDetailsElement).open;
                      },
                    },
                    [
                      summary(id: _id('more-options-toggle'), const [
                        Component.text('More options'),
                      ]),
                      _toggle(
                        'infer_missing_required',
                        'Infer missing required fields',
                      ),
                      _toggle(
                        'use_presence_records',
                        'Preserve absent vs. null',
                      ),
                      _toggle('generate_validators', 'Generate DTO validators'),
                      _toggle('prune_unused_models', 'Remove unused models'),
                      _toggle(
                        'body_positional',
                        'Use positional body arguments',
                      ),
                      _toggle(
                        'apply_parameter_defaults',
                        'Apply parameter defaults',
                      ),
                      _toggle(
                        'original_http_response',
                        'Return the original response',
                      ),
                    ],
                  ),
                ],
                if (_configError case final message?)
                  div(
                    id: _id('config-error'),
                    classes: 'notice error',
                    attributes: const {'role': 'alert'},
                    [Component.text(message)],
                  ),
                const div(classes: 'generation-note', [
                  span(classes: 'note-symbol', [Component.text('↳')]),
                  p([
                    Component.text(
                      'ZIP preserves client and model folders. Run build_runner in your app for package-generated parts.',
                    ),
                  ]),
                ]),
              ]),
            ]),
          ]),
        ],
      ),
      section(classes: 'feature-strip', [
        _feature(
          '4 serializers',
          'Plain Dart, json_serializable, Freezed, and dart_mappable.',
        ),
        _feature(
          '3 HTTP clients',
          'Retrofit + Dio, standalone Dio, or package:http.',
        ),
        _feature(
          'Your own templates',
          'Extend output with swagger_parser_templates.',
        ),
      ]),
    ]),
  ]);

  Component _templateEditor() => section(classes: 'panel template-panel', [
    const div(classes: 'panel-heading', [
      h2([Component.text('Mustache templates')]),
    ]),
    div(classes: 'template-body', [
      const p(classes: 'field-help', [
        Component.text(
          'Use overrides for api, exports, models, client, results, support, or an exact output path. Use files to add Dart helpers. Sources are inline text, not file paths.',
        ),
      ]),
      label(htmlFor: _id('source'), classes: 'field-label', const [
        Component.text('Template sources (YAML or JSON)'),
      ]),
      textarea(
        id: _id('source'),
        classes: 'code-editor template-editor',
        spellCheck: SpellCheck.isFalse,
        onInput: (value) => _templateSource = value,
        [Component.text(_templateSource)],
      ),
      const p(classes: 'field-help template-help', [
        Component.text(
          'Keep {{defaultSource}} to extend built-in code. Context: relativePath, kind, options, library. Helpers are exported by default. Invalid templates or conflicting paths stop the download.',
        ),
      ]),
    ]),
  ]);

  Component _step(
    String number,
    String title,
    String description, {
    bool muted = false,
  }) => div(classes: 'workflow-step${muted ? ' muted' : ''}', [
    span(classes: 'workflow-number', [Component.text(number)]),
    div([
      h3([Component.text(title)]),
      p([Component.text(description)]),
    ]),
  ]);

  Component _select(String key, String title, Map<String, String> values) =>
      div(classes: 'field', [
        label(htmlFor: _id(key), classes: 'field-label', [
          Component.text(title),
        ]),
        select(
          id: _id(key),
          value: _config.value(key) as String,
          onChange: (value) => _setOption(key, value.single),
          [
            for (final MapEntry<String, String> entry in values.entries)
              option(
                value: entry.key,
                selected: entry.key == _config.value(key),
                [Component.text(entry.value)],
              ),
          ],
        ),
      ]);

  Component _input(String key, String title, {bool numeric = false}) => div(
    classes: 'field',
    [
      label(htmlFor: _id(key), classes: 'field-label', [Component.text(title)]),
      input<String>(
        id: _id(key),
        value: '${_config.value(key)}',
        attributes: {if (numeric) 'inputmode': 'numeric'},
        onChange: (value) =>
            _setOption(key, numeric ? int.tryParse(value) ?? value : value),
      ),
    ],
  );

  Component _toggle(String key, String title) =>
      label(classes: 'toggle-field', [
        input<bool>(
          id: _id(key),
          type: InputType.checkbox,
          checked: _config.value(key) as bool,
          onChange: (value) => _setOption(key, value),
        ),
        span([Component.text(title)]),
      ]);

  Component _feature(String title, String description) => div([
    h3([Component.text(title)]),
    p([Component.text(description)]),
  ]);
}
