import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:swagger_parser/swagger_parser.dart';
import 'package:swagger_parser_pages/utils/file_utils.dart';

class GeneratorContent extends StatefulWidget {
  const GeneratorContent({super.key});

  @override
  State<GeneratorContent> createState() => _GeneratorContentState();
}

class _GeneratorContentState extends State<GeneratorContent> {
  late final _fileContent = TextEditingController();
  late final _nameController = TextEditingController(text: 'api');
  late final _rootClientName = TextEditingController(text: 'RestClient');
  late final _clientPostfix = TextEditingController();
  ProgrammingLanguage _language = ProgrammingLanguage.dart;
  JsonSerializer _jsonSerializer = JsonSerializer.jsonSerializable;
  bool _isJson = false;
  bool _rootClient = true;
  bool _putClientsInFolder = false;
  bool _enumsToJson = false;
  bool _enumsParentPrefix = false;
  bool _unknownEnumValue = true;
  bool _pathMethodName = false;
  bool _mergeClients = false;
  bool _markFilesAsGenerated = true;

  @override
  void dispose() {
    _fileContent.dispose();
    _nameController.dispose();
    _rootClientName.dispose();
    _clientPostfix.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: Wrap(
      runSpacing: 20,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['json', 'yaml', 'JSON', 'YAML'],
                      );
                      if (result != null) {
                        final fileBytes = result.files.first.bytes;
                        final fileName = result.files.first.name;
                        setState(() {
                          _isJson =
                              fileName.split('.').lastOrNull?.toLowerCase() !=
                              'yaml';
                        });
                        if (fileBytes != null) {
                          final s = utf8.decode(fileBytes);
                          _fileContent.text = s;
                        }
                      }
                    },
                    child: const Text('Choose file'),
                  ),
                ),
                const SizedBox(height: 24),
                ListenableBuilder(
                  listenable: _fileContent,
                  builder: (context, child) => _fileContent.text.isEmpty
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(bottom: 48),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xb3c92b16),
                              ),
                              onPressed: () async {
                                _fileContent.clear();
                              },
                              child: const Text('Clear'),
                            ),
                          ),
                        ),
                ),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Paste your OpenApi definition file content',
                      hintStyle: const TextStyle(fontSize: 18),
                    ),
                    controller: _fileContent,
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
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Config parameters',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 24),
                Center(
                  child: DropdownMenu<ProgrammingLanguage>(
                    label: const Text('Language'),
                    width: 300,
                    initialSelection: ProgrammingLanguage.dart,
                    dropdownMenuEntries: ProgrammingLanguage.values
                        .map((e) => DropdownMenuEntry(value: e, label: e.name))
                        .toList(growable: false),
                    onSelected: (lng) => setState(() => _language = lng!),
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 600),
                  crossFadeState: _language == ProgrammingLanguage.dart
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  sizeCurve: Curves.fastOutSlowIn,
                  // for correct animation
                  firstChild: Container(),
                  secondChild: Center(
                    child: DropdownMenu<JsonSerializer>(
                      label: const Text('Json serializer'),
                      width: 300,
                      initialSelection: JsonSerializer.jsonSerializable,
                      dropdownMenuEntries: JsonSerializer.values
                          .map(
                            (e) => DropdownMenuEntry(value: e, label: e.name),
                          )
                          .toList(growable: false),
                      onSelected: (js) => setState(() => _jsonSerializer = js!),
                    ),
                  ),
                ),
                TextField(
                  controller: _clientPostfix,
                  decoration: const InputDecoration(
                    labelStyle: TextStyle(fontSize: 18),
                    hintText: 'Name',
                    hintStyle: TextStyle(fontSize: 18),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  style: const TextStyle(fontSize: 24),
                ),
                StatefulBuilder(
                  builder: (context, setState) => CheckboxListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text('Is JSON file content'),
                    value: _isJson,
                    onChanged: (value) => setState(() => _isJson = value!),
                  ),
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 600),
                  crossFadeState: _language == ProgrammingLanguage.dart
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  sizeCurve: Curves.fastOutSlowIn,
                  firstChild: Container(),
                  secondChild: TextField(
                    controller: _rootClientName,
                    decoration: const InputDecoration(
                      labelStyle: TextStyle(fontSize: 18),
                      hintText: 'Root client name',
                      hintStyle: TextStyle(fontSize: 18),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 600),
                  crossFadeState: _language == ProgrammingLanguage.dart
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  sizeCurve: Curves.fastOutSlowIn,
                  firstChild: Container(),
                  secondChild: StatefulBuilder(
                    builder: (context, setState) => CheckboxListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text(
                        'Generate root client for REST clients',
                      ),
                      value: _rootClient,
                      onChanged: (value) =>
                          setState(() => _rootClient = value!),
                    ),
                  ),
                ),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelStyle: TextStyle(fontSize: 18),
                    hintText: 'Postfix for client classes',
                    hintStyle: TextStyle(fontSize: 18),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  style: const TextStyle(fontSize: 24),
                ),
                StatefulBuilder(
                  builder: (context, setState) => CheckboxListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text('Put all clients in clients folder'),
                    value: _putClientsInFolder,
                    onChanged: (value) =>
                        setState(() => _putClientsInFolder = value!),
                  ),
                ),
                StatefulBuilder(
                  builder: (context, setState) => CheckboxListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text('Squash all clients in one client'),
                    value: _mergeClients,
                    onChanged: (value) =>
                        setState(() => _mergeClients = value!),
                  ),
                ),
                StatefulBuilder(
                  builder: (context, setState) => CheckboxListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text('Generate method name from url path'),
                    value: _pathMethodName,
                    onChanged: (value) =>
                        setState(() => _pathMethodName = value!),
                  ),
                ),
                StatefulBuilder(
                  builder: (context, setState) => CheckboxListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text('Mark files as generated'),
                    value: _markFilesAsGenerated,
                    onChanged: (value) =>
                        setState(() => _markFilesAsGenerated = value!),
                  ),
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 600),
                  crossFadeState: _language == ProgrammingLanguage.dart
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  sizeCurve: Curves.fastOutSlowIn,
                  // for correct animation
                  firstChild: Container(),
                  secondChild: StatefulBuilder(
                    builder: (context, setState) => CheckboxListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text('Generate to json in Enum'),
                      value: _enumsToJson,
                      onChanged: (value) =>
                          setState(() => _enumsToJson = value!),
                    ),
                  ),
                ),
                StatefulBuilder(
                  builder: (context, setState) => CheckboxListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text(
                      'Generate enum name with prefix from parent component',
                    ),
                    value: _enumsParentPrefix,
                    onChanged: (value) =>
                        setState(() => _enumsParentPrefix = value!),
                  ),
                ),
                StatefulBuilder(
                  builder: (context, setState) => CheckboxListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text(r'Generate $unknown element in enums'),
                    value: _unknownEnumValue,
                    onChanged: (value) =>
                        setState(() => _unknownEnumValue = value!),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  child: OutlinedButton(
                    child: const Text(
                      'Generate and download',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24),
                    ),
                    onPressed: () async {
                      await _generateOutputs(
                        context,
                        config: SWPConfig(
                          outputDirectory: '',
                          name: _nameController.text,
                          language: _language,
                          jsonSerializer: _jsonSerializer,
                          rootClient: _rootClient,
                          rootClientName: _rootClientName.text,
                          clientPostfix: _clientPostfix.text,
                          putClientsInFolder: _putClientsInFolder,
                          enumsParentPrefix: _enumsParentPrefix,
                          enumsToJson: _enumsToJson,
                          unknownEnumValue: _unknownEnumValue,
                          markFilesAsGenerated: _markFilesAsGenerated,
                          pathMethodName: _pathMethodName,
                          mergeClients: _mergeClients,
                        ),
                        fileContent: _fileContent.text,
                        isJson: _isJson,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Future<void> _generateOutputs(
  BuildContext context, {
  required SWPConfig config,
  required String fileContent,
  required bool isJson,
}) async {
  final sm = ScaffoldMessenger.of(context);
  final generator = GenProcessor(config);
  try {
    final files = await generator.generateContent((
      fileContent: fileContent,
      isJson: isJson,
    ));
    generateArchive(files);
  } on Object catch (e, st) {
    sm.showSnackBar(
      SnackBar(
        content: Text(e.toString()),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Error.throwWithStackTrace(e, st);
  }
}
