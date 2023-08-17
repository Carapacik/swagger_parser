import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:swagger_parser/swagger_parser.dart';
import 'package:swagger_parser_pages/utils/file_utils.dart';

class GeneratorContent extends StatefulWidget {
  const GeneratorContent({super.key});

  @override
  State<GeneratorContent> createState() => _GeneratorContentState();
}

class _GeneratorContentState extends State<GeneratorContent> {
  late final TextEditingController _schemaController;
  late final TextEditingController _clientPostfix;
  ProgrammingLanguage _language = ProgrammingLanguage.dart;
  bool _isYaml = false;
  bool _includeToJsonInEnums = false;
  bool _freezed = false;
  bool _rootInterface = true;
  bool _squishClients = false;

  @override
  void initState() {
    super.initState();
    _schemaController = TextEditingController();
    _clientPostfix = TextEditingController();
  }

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
                constraints: const BoxConstraints(maxWidth: 400, maxHeight: 300),
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
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
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
                      crossFadeState:
                          _language == ProgrammingLanguage.dart ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      sizeCurve: Curves.fastOutSlowIn,
                      firstChild: Container(),
                      secondChild: StatefulBuilder(
                        builder: (context, setState) => CheckboxListTile(
                          title: const Text(
                            'Generate root interface for REST clients',
                          ),
                          value: _rootInterface,
                          onChanged: (value) => setState(() => _rootInterface = value!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    StatefulBuilder(
                      builder: (context, setState) => CheckboxListTile(
                        title: const Text('Is YAML file content'),
                        value: _isYaml,
                        onChanged: (value) => setState(() => _isYaml = value!),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _clientPostfix,
                      decoration: const InputDecoration(
                        labelStyle: TextStyle(fontSize: 24),
                        hintText: 'Postfix for client classes',
                        hintStyle: TextStyle(fontSize: 24),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 16),
                    StatefulBuilder(
                      builder: (context, setState) {
                        return CheckboxListTile(
                          title: const Text('Squish client folders into one?'),
                          value: _squishClients,
                          onChanged: (value) => setState(() => _squishClients = value!),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 600),
                      crossFadeState:
                          _language == ProgrammingLanguage.dart ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      sizeCurve: Curves.fastOutSlowIn,
                      // for correct animation
                      firstChild: Container(),
                      secondChild: StatefulBuilder(
                        builder: (context, setState) => CheckboxListTile(
                          title: const Text('Generate to json in Enum'),
                          value: _includeToJsonInEnums,
                          onChanged: (value) => setState(() => _includeToJsonInEnums = value!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 600),
                      crossFadeState:
                          _language == ProgrammingLanguage.dart ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      sizeCurve: Curves.fastOutSlowIn,
                      // for correct animation
                      firstChild: Container(),
                      secondChild: StatefulBuilder(
                        builder: (context, setState) => CheckboxListTile(
                          title: const Text('Use freezed'),
                          value: _freezed,
                          onChanged: (value) => setState(() => _freezed = value!),
                        ),
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
                            freezed: _freezed,
                            squishClients: _squishClients,
                            isYaml: _isYaml,
                            rootInterface: _rootInterface,
                            includeToJsonInEnums: _includeToJsonInEnums,
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
  required bool includeToJsonInEnums,
}) async {
  final sm = ScaffoldMessenger.of(context);
  final generator = Generator.fromString(
    schemaContent: schema,
    language: language,
    clientPostfix: clientPostfix.trim().isEmpty ? null : clientPostfix,
    freezed: freezed,
    squishClients: squishClients,
    isYaml: isYaml,
    includeToJsonInEnums: includeToJsonInEnums,
    rootInterface: rootInterface,
    replacementRules: [],
  );
  try {
    final files = await generator.generateContent();
    generateArchive(files);
  } on Object catch (e, st) {
    if (kDebugMode) {
      print(e);
    }
    sm.showSnackBar(
      SnackBar(
        content: Text(e.toString()),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Error.throwWithStackTrace(e, st);
  }
}
