import 'package:flutter/material.dart';
import 'package:swagger_parser/swagger_parser.dart';
import 'package:swagger_parser_pages/utils/file_utils.dart';

class GeneratorContent extends StatefulWidget {
  const GeneratorContent({super.key});

  @override
  State<GeneratorContent> createState() => _GeneratorContentState();
}

class _GeneratorContentState extends State<GeneratorContent> {
  late final _schemaController = TextEditingController();
  late final _clientPostfix = TextEditingController();
  late final _name = TextEditingController();
  late final _rootClientName = TextEditingController();
  ProgrammingLanguage _language = ProgrammingLanguage.dart;
  JsonSerializer _jsonSerializer = JsonSerializer.jsonSerializable;
  bool _isYaml = false;
  bool _rootClient = true;
  bool _putClientsInFolder = false;
  bool _putInFolder = false;
  bool _pathMethodName = false;
  bool _squashClients = false;
  bool _markFilesAsGenerated = true;
  bool _enumsToJson = false;
  bool _enumsPrefix = false;

  @override
  void dispose() {
    _schemaController.dispose();
    _clientPostfix.dispose();
    _name.dispose();
    _rootClientName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 20,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 400, maxHeight: 500),
                child: TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: 'Paste your OpenApi definition file content',
                    hintStyle: const TextStyle(fontSize: 18),
                  ),
                  controller: _schemaController,
                  keyboardType: TextInputType.multiline,
                  textAlignVertical: TextAlignVertical.top,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(fontSize: 18),
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
                      style:
                          TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: DropdownMenu<ProgrammingLanguage>(
                        label: const Text('Language'),
                        width: 300,
                        initialSelection: ProgrammingLanguage.dart,
                        dropdownMenuEntries: ProgrammingLanguage.values
                            .map(
                              (e) => DropdownMenuEntry(value: e, label: e.name),
                            )
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
                                (e) =>
                                    DropdownMenuEntry(value: e, label: e.name),
                              )
                              .toList(growable: false),
                          onSelected: (js) =>
                              setState(() => _jsonSerializer = js!),
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
                        title: const Text('Is YAML file content'),
                        value: _isYaml,
                        onChanged: (value) => setState(() => _isYaml = value!),
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
                      controller: _name,
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
                        title: const Text('Put the all api in its folder'),
                        value: _putInFolder,
                        onChanged: (value) =>
                            setState(() => _putInFolder = value!),
                      ),
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
                        value: _squashClients,
                        onChanged: (value) =>
                            setState(() => _squashClients = value!),
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
                        value: _enumsPrefix,
                        onChanged: (value) =>
                            setState(() => _enumsPrefix = value!),
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
                            schema: _schemaController.text,
                            clientPostfix: _clientPostfix.text,
                            language: _language,
                            isYaml: _isYaml,
                            jsonSerializer: _jsonSerializer,
                            rootClient: _rootClient,
                            rootClientName: _rootClientName.text,
                            name: _name.text,
                            putInFolder: _putInFolder,
                            putClientsInFolder: _putClientsInFolder,
                            pathMethodName: _pathMethodName,
                            squashClients: _squashClients,
                            markFilesAsGenerated: _markFilesAsGenerated,
                            enumsToJson: _enumsToJson,
                            enumsPrefix: _enumsPrefix,
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
  required String schema,
  required String clientPostfix,
  required ProgrammingLanguage language,
  required JsonSerializer jsonSerializer,
  required String name,
  required bool putInFolder,
  required bool putClientsInFolder,
  required bool squashClients,
  required bool isYaml,
  required bool rootClient,
  required String rootClientName,
  required bool pathMethodName,
  required bool enumsToJson,
  required bool enumsPrefix,
  required bool markFilesAsGenerated,
}) async {
  final sm = ScaffoldMessenger.of(context);
  final generator = Generator(
    schemaContent: schema,
    isYaml: isYaml,
    language: language,
    outputDirectory: '',
    jsonSerializer: jsonSerializer,
    rootClient: rootClient,
    rootClientName: rootClientName.trim().isEmpty ? null : rootClientName,
    clientPostfix: clientPostfix.trim().isEmpty ? null : clientPostfix,
    name: name.trim().isEmpty ? null : name,
    putInFolder: putInFolder,
    putClientsInFolder: putClientsInFolder,
    squashClients: squashClients,
    pathMethodName: pathMethodName,
    enumsToJson: enumsToJson,
    enumsPrefix: enumsPrefix,
    markFilesAsGenerated: markFilesAsGenerated,
    replacementRules: [],
  );
  try {
    final files = await generator.generateContent();
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
