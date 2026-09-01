import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:swagger_parser/swagger_parser.dart';
import 'package:swagger_parser_pages/src/generator/config_value_parser.dart';
import 'package:swagger_parser_pages/src/web/archive_downloader.dart';

class const GeneratorContent({super.key}) extends StatefulWidget {
  @override
  State<GeneratorContent> createState() => _GeneratorContentState();
}

class _GeneratorContentState() extends State<GeneratorContent> {
  final _fileContent = TextEditingController();
  final _name = TextEditingController(text: 'api');
  final _rootClientName = TextEditingController(text: 'RestClient');
  final _clientPostfix = TextEditingController();
  final _defaultContentType = TextEditingController(text: 'application/json');
  final _fallbackUnion = TextEditingController();
  final _fallbackClient = TextEditingController(text: 'fallback');
  final _skippedParameters = TextEditingController();
  final _excludeTags = TextEditingController();
  final _includeTags = TextEditingController();
  final _includePaths = TextEditingController();
  final _replacementRules = TextEditingController();
  final _rawReplacementRules = TextEditingController();
  final _fieldParsers = TextEditingController();

  ProgrammingLanguage _language = ProgrammingLanguage.dart;
  JsonSerializer _jsonSerializer = JsonSerializer.jsonSerializable;
  bool _isJson = false;
  bool _isGenerating = false;
  bool _rootClient = true;
  bool _exportFile = true;
  bool _putClientsInFolder = false;
  bool _enumsToJson = false;
  bool _enumsParentPrefix = true;
  bool _unknownEnumValue = true;
  bool _pathMethodName = false;
  bool _mergeClients = false;
  bool _mergeOutputs = false;
  bool _markFilesAsGenerated = true;
  bool _originalHttpResponse = false;
  bool _extrasParameterByDefault = false;
  bool _dioOptionsParameterByDefault = false;
  bool _addOpenApiMetadata = false;
  bool _generateValidator = false;
  bool _useXNullable = false;
  bool _useFreezed3 = false;
  bool _useMultipartFile = false;
  bool _dartMappableConvenientWhen = false;
  bool _useDartMappableNaming = false;
  bool _includeIfNull = false;
  bool _inferRequiredFromNullable = false;
  bool _useFlutterCompute = false;
  bool _generateUrlsConstants = false;
  bool _preserveSchemaCasing = false;

  bool get _isDart => _language == ProgrammingLanguage.dart;

  @override
  void dispose() {
    for (final controller in <TextEditingController>[
      _fileContent,
      _name,
      _rootClientName,
      _clientPostfix,
      _defaultContentType,
      _fallbackUnion,
      _fallbackClient,
      _skippedParameters,
      _excludeTags,
      _includeTags,
      _includePaths,
      _replacementRules,
      _rawReplacementRules,
      _fieldParsers,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: Wrap(
      runSpacing: 20,
      children: [
        _schemaInput(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Config parameters',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                _basicSettings(),
                _dartSettings(),
                _filterSettings(),
                _advancedSettings(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isGenerating ? null : _generate,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: _isGenerating
                          ? const CircularProgressIndicator()
                          : const Text(
                              'Generate and download',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 24),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _schemaInput() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _pickSchema,
              child: const Text('Choose OpenAPI file'),
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('YAML')),
              ButtonSegment(value: true, label: Text('JSON')),
            ],
            selected: {_isJson},
            onSelectionChanged: (selection) {
              setState(() => _isJson = selection.single);
            },
          ),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: _fileContent,
            builder: (context, child) => _fileContent.text.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xb3c92b16),
                        ),
                        onPressed: _fileContent.clear,
                        child: const Text('Clear'),
                      ),
                    ),
                  ),
          ),
          Expanded(
            child: TextField(
              controller: _fileContent,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Paste your OpenAPI YAML or JSON definition',
                hintStyle: const TextStyle(fontSize: 18),
              ),
              keyboardType: TextInputType.multiline,
              textAlignVertical: TextAlignVertical.top,
              maxLines: null,
              expands: true,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _basicSettings() => _section(
    title: 'Basic',
    initiallyExpanded: true,
    children: [
      DropdownMenu<ProgrammingLanguage>(
        label: const Text('Language'),
        expandedInsets: EdgeInsets.zero,
        initialSelection: _language,
        dropdownMenuEntries: ProgrammingLanguage.values
            .map((value) => DropdownMenuEntry(value: value, label: value.name))
            .toList(growable: false),
        onSelected: (value) {
          if (value != null) {
            setState(() => _language = value);
          }
        },
      ),
      if (_isDart) ...[
        const SizedBox(height: 12),
        DropdownMenu<JsonSerializer>(
          label: const Text('JSON serializer'),
          expandedInsets: EdgeInsets.zero,
          initialSelection: _jsonSerializer,
          dropdownMenuEntries: JsonSerializer.values
              .map(
                (value) => DropdownMenuEntry(value: value, label: value.name),
              )
              .toList(growable: false),
          onSelected: (value) {
            if (value != null) {
              setState(() => _jsonSerializer = value);
            }
          },
        ),
      ],
      _textField(_name, 'API name'),
      _textField(_clientPostfix, 'Client postfix'),
      _switch(
        'Put clients in a clients folder',
        _putClientsInFolder,
        (value) => _putClientsInFolder = value,
      ),
      _switch(
        'Merge all clients',
        _mergeClients,
        (value) => _mergeClients = value,
      ),
      _switch(
        'Merge all outputs into one file',
        _mergeOutputs,
        (value) => _mergeOutputs = value,
      ),
      _switch(
        'Use path for method names',
        _pathMethodName,
        (value) => _pathMethodName = value,
      ),
      _switch(
        'Mark files as generated',
        _markFilesAsGenerated,
        (value) => _markFilesAsGenerated = value,
      ),
      _switch(
        'Preserve schema casing',
        _preserveSchemaCasing,
        (value) => _preserveSchemaCasing = value,
      ),
    ],
  );

  Widget _dartSettings() => _section(
    title: 'Dart options',
    enabled: _isDart,
    children: [
      _switch(
        'Generate root client',
        _rootClient,
        (value) => _rootClient = value,
      ),
      if (_rootClient) _textField(_rootClientName, 'Root client name'),
      _switch(
        'Generate export file',
        _exportFile,
        (value) => _exportFile = value,
      ),
      _switch(
        'Generate enum toJson()',
        _enumsToJson,
        (value) => _enumsToJson = value,
      ),
      _switch(
        r'Generate $unknown enum value',
        _unknownEnumValue,
        (value) => _unknownEnumValue = value,
      ),
      _switch(
        'Prefix enum names with parent',
        _enumsParentPrefix,
        (value) => _enumsParentPrefix = value,
      ),
      _switch(
        'Wrap responses in HttpResponse',
        _originalHttpResponse,
        (value) => _originalHttpResponse = value,
      ),
      _textField(_defaultContentType, 'Default content type'),
      _switch(
        'Add Extras parameter by default',
        _extrasParameterByDefault,
        (value) => _extrasParameterByDefault = value,
      ),
      _switch(
        'Add DioOptions parameter by default',
        _dioOptionsParameterByDefault,
        (value) => _dioOptionsParameterByDefault = value,
      ),
      _switch(
        'Add OpenAPI metadata',
        _addOpenApiMetadata,
        (value) => _addOpenApiMetadata = value,
      ),
      if (_jsonSerializer == JsonSerializer.freezed) ...[
        _switch(
          'Generate validators',
          _generateValidator,
          (value) => _generateValidator = value,
        ),
        _switch(
          'Use Freezed 3 syntax',
          _useFreezed3,
          (value) => _useFreezed3 = value,
        ),
        _textField(_fallbackUnion, 'Fallback union constructor'),
      ],
      if (_jsonSerializer == JsonSerializer.dartMappable) ...[
        _switch(
          'Generate convenient when methods',
          _dartMappableConvenientWhen,
          (value) => _dartMappableConvenientWhen = value,
        ),
        _switch(
          'Use dart_mappable naming',
          _useDartMappableNaming,
          (value) => _useDartMappableNaming = value,
        ),
      ],
      _switch(
        'Use x-nullable',
        _useXNullable,
        (value) => _useXNullable = value,
      ),
      _switch(
        'Use MultipartFile',
        _useMultipartFile,
        (value) => _useMultipartFile = value,
      ),
      _switch(
        'Generate includeIfNull',
        _includeIfNull,
        (value) => _includeIfNull = value,
      ),
      _switch(
        'Infer required from nullable',
        _inferRequiredFromNullable,
        (value) => _inferRequiredFromNullable = value,
      ),
      _switch(
        'Use Flutter compute parser',
        _useFlutterCompute,
        (value) => _useFlutterCompute = value,
      ),
      _switch(
        'Generate URL constants',
        _generateUrlsConstants,
        (value) => _generateUrlsConstants = value,
      ),
    ],
  );

  Widget _filterSettings() => _section(
    title: 'Filtering',
    children: [
      _textField(
        _skippedParameters,
        'Skipped parameters',
        hint: 'id, internalToken',
        maxLines: 2,
      ),
      _textField(
        _includeTags,
        'Include tags',
        hint: 'public, users',
        maxLines: 2,
      ),
      _textField(
        _excludeTags,
        'Exclude tags',
        hint: 'admin, internal',
        maxLines: 2,
      ),
      _textField(
        _includePaths,
        'Include paths',
        hint: '/users/**, /health',
        maxLines: 2,
      ),
      _textField(_fallbackClient, 'Fallback client name'),
    ],
  );

  Widget _advancedSettings() => _section(
    title: 'Advanced mappings',
    children: [
      _textField(
        _replacementRules,
        'Replacement rules',
        hint: 'pattern => replacement',
        maxLines: 4,
      ),
      _textField(
        _rawReplacementRules,
        'Raw schema replacement rules',
        hint: 'pattern => replacement',
        maxLines: 4,
      ),
      _textField(
        _fieldParsers,
        'Field parsers',
        hint: 'Type | parserName | package:path/parser.dart',
        maxLines: 4,
      ),
    ],
  );

  Widget _section({
    required String title,
    required List<Widget> children,
    bool initiallyExpanded = false,
    bool enabled = true,
  }) => Card(
    child: ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      enabled: enabled,
      title: Text(title),
      subtitle: enabled ? null : const Text('Available for Dart only'),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: children,
    ),
  );

  Widget _textField(
    TextEditingController controller,
    String label, {
    String? hint,
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    ),
  );

  Widget _switch(String title, bool value, ValueChanged<bool> update) =>
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        value: value,
        onChanged: (nextValue) => setState(() => update(nextValue)),
      );

  Future<void> _pickSchema() async {
    final PlatformFile? file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['json', 'yaml', 'yml'],
    );
    if (file == null) {
      return;
    }

    final List<int> fileBytes = await file.readAsBytes();
    if (!mounted) {
      return;
    }

    setState(() {
      _isJson = file.extension?.toLowerCase() == 'json';
      _fileContent.text = utf8.decode(fileBytes);
    });
  }

  Future<void> _generate() async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() => _isGenerating = true);

    try {
      if (_fileContent.text.trim().isEmpty) {
        throw const FormatException('Paste or choose an OpenAPI schema first.');
      }
      final generator = GenProcessor(_buildConfig());
      final List<GeneratedFile> files = await generator.generateContent((
        fileContent: _fileContent.text,
        isJson: _isJson,
      ));
      downloadArchive(files);
    } on Object catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  SWPConfig _buildConfig() => SWPConfig(
    outputDirectory: '',
    name: _name.text.trim(),
    language: _language,
    jsonSerializer: _jsonSerializer,
    rootClient: _rootClient,
    rootClientName: _rootClientName.text.trim(),
    clientPostfix: _nullableText(_clientPostfix),
    exportFile: _exportFile,
    putClientsInFolder: _putClientsInFolder,
    enumsToJson: _enumsToJson,
    unknownEnumValue: _unknownEnumValue,
    markFilesAsGenerated: _markFilesAsGenerated,
    originalHttpResponse: _originalHttpResponse,
    replacementRules: parseReplacementRules(_replacementRules.text),
    replacementRulesForRawSchema: parseReplacementRules(
      _rawReplacementRules.text,
    ),
    defaultContentType: _defaultContentType.text.trim(),
    extrasParameterByDefault: _extrasParameterByDefault,
    dioOptionsParameterByDefault: _dioOptionsParameterByDefault,
    addOpenApiMetadata: _addOpenApiMetadata,
    pathMethodName: _pathMethodName,
    mergeClients: _mergeClients,
    enumsParentPrefix: _enumsParentPrefix,
    skippedParameters: parseConfigList(_skippedParameters.text),
    generateValidator: _generateValidator,
    useXNullable: _useXNullable,
    useFreezed3: _useFreezed3,
    useMultipartFile: _useMultipartFile,
    fallbackUnion: _nullableText(_fallbackUnion),
    dartMappableConvenientWhen: _dartMappableConvenientWhen,
    useDartMappableNaming: _useDartMappableNaming,
    excludeTags: parseConfigList(_excludeTags.text),
    includeTags: parseConfigList(_includeTags.text),
    includePaths: parseConfigList(_includePaths.text).nullIfEmpty,
    fallbackClient: _fallbackClient.text.trim(),
    mergeOutputs: _mergeOutputs,
    includeIfNull: _includeIfNull,
    inferRequiredFromNullable: _inferRequiredFromNullable,
    useFlutterCompute: _useFlutterCompute,
    generateUrlsConstants: _generateUrlsConstants,
    fieldParsers: parseFieldParsers(_fieldParsers.text),
    preserveSchemaCasing: _preserveSchemaCasing,
  );
}

String? _nullableText(TextEditingController controller) {
  final String value = controller.text.trim();
  return value.isEmpty ? null : value;
}
