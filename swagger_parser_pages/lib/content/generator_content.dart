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
  late final _rootClientName = TextEditingController();
  ProgrammingLanguage _language = ProgrammingLanguage.dart;
  bool _isYaml = false;
  bool _freezed = false;
  bool _rootInterface = true;
  bool _squishClients = false;
  bool _pathMethodName = false;
  bool _markFilesAsGenerated = false;
  bool _enumsToJson = false;
  bool _enumsPrefix = false;

  @override
  void dispose() {
    _schemaController.dispose();
    _clientPostfix.dispose();
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
                      secondChild: StatefulBuilder(
                        builder: (context, setState) => CheckboxListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Text('Use freezed'),
                          value: _freezed,
                          onChanged: (value) =>
                              setState(() => _freezed = value!),
                        ),
                      ),
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
                      secondChild: StatefulBuilder(
                        builder: (context, setState) => CheckboxListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Text(
                            'Generate root interface for REST clients',
                          ),
                          value: _rootInterface,
                          onChanged: (value) =>
                              setState(() => _rootInterface = value!),
                        ),
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
                    TextField(
                      controller: _clientPostfix,
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
                        title: const Text('Squish client folders into one?'),
                        value: _squishClients,
                        onChanged: (value) =>
                            setState(() => _squishClients = value!),
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
                            freezed: _freezed,
                            rootInterface: _rootInterface,
                            rootClientName: _rootClientName.text,
                            squishClients: _squishClients,
                            pathMethodName: _pathMethodName,
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
  required bool freezed,
  required bool squishClients,
  required bool isYaml,
  required bool rootInterface,
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
    freezed: freezed,
    rootInterface: rootInterface,
    rootClientName: rootClientName.trim().isEmpty ? null : rootClientName,
    clientPostfix: clientPostfix.trim().isEmpty ? null : clientPostfix,
    squishClients: squishClients,
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
