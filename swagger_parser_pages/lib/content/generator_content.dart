import 'package:flutter/material.dart';
import 'package:swagger_parser/swagger_parser.dart';
import 'package:swagger_parser_pages/utils/file_utils.dart';
import 'package:swagger_parser_pages/widgets/labeled_checkbox.dart';

class GeneratorContent extends StatefulWidget {
  const GeneratorContent({super.key});

  @override
  State<GeneratorContent> createState() => _GeneratorContentState();
}

class _GeneratorContentState extends State<GeneratorContent> {
  late final TextEditingController _jsonController;
  late final TextEditingController _clientPostfix;
  ProgrammingLanguage _language = ProgrammingLanguage.dart;
  bool _isYamlFile = false;
  bool _isFreezed = false;
  bool _squishClients = false;

  @override
  void initState() {
    super.initState();
    _jsonController = TextEditingController();
    _clientPostfix = TextEditingController();
  }

  @override
  void dispose() {
    _jsonController.dispose();
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
                  controller: _jsonController,
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
                  children: [
                    const Text(
                      'Config parameters',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 24),
                    DropdownButton<String>(
                      value: _language.name,
                      style: const TextStyle(fontSize: 24, color: Colors.white),
                      isExpanded: true,
                      icon: const RotatedBox(
                        quarterTurns: 1,
                        child: Icon(Icons.arrow_forward_ios_sharp),
                      ),
                      underline: const SizedBox.shrink(),
                      elevation: 16,
                      onChanged: (value) => setState(
                        () => _language = ProgrammingLanguage.fromString(value)!,
                      ),
                      items: ProgrammingLanguage.values
                          .map<DropdownMenuItem<String>>(
                            (value) => DropdownMenuItem<String>(
                              value: value.name,
                              child: Text(value.name),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    LabeledCheckbox(
                      label: 'Is YAML file content',
                      value: _isYamlFile,
                      onChanged: (newValue) {
                        setState(() {
                          _isYamlFile = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _clientPostfix,
                      decoration: const InputDecoration(
                        labelStyle: TextStyle(fontSize: 24),
                        hintText: 'Postfix for client classes',
                        hintStyle: TextStyle(fontSize: 24),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 16),
                    LabeledCheckbox(
                      label: 'Squish client folders into one?',
                      value: _squishClients,
                      onChanged: (newValue) {
                        setState(() {
                          _squishClients = newValue;
                        });
                      },
                    ),
                    if (_language == ProgrammingLanguage.dart) ...[
                      const SizedBox(height: 16),
                      LabeledCheckbox(
                        label: 'Use freezed?',
                        value: _isFreezed,
                        onChanged: (newValue) {
                          setState(() {
                            _isFreezed = newValue;
                          });
                        },
                      ),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      width: 300,
                      height: 40,
                      child: OutlinedButton(
                        child: const Text(
                          'Generate and download',
                          style: TextStyle(fontSize: 24),
                        ),
                        onPressed: () async {
                          await generateOutputs(
                            context,
                            json: _jsonController.text,
                            clientPostfix: _clientPostfix.text,
                            language: _language,
                            useFreezed: _isFreezed,
                            squishClients: _squishClients,
                            isYaml: _isYamlFile,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      );
}

Future<void> generateOutputs(
  BuildContext context, {
  required String json,
  required String clientPostfix,
  required ProgrammingLanguage language,
  required bool useFreezed,
  required bool squishClients,
  required bool isYaml,
}) async {
  final generator = Generator.fromString(
    jsonContent: json,
    language: language,
    clientPostfix: clientPostfix,
    freezed: useFreezed,
    squishClients: squishClients,
    isYaml: isYaml,
  );
  try {
    final files = await generator.generateContent();
    generateArchive(files);
  } on Object catch (e) {
    debugPrint(e.toString());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
