import 'dart:developer';

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
  late final TextEditingController _schemaController;
  late final TextEditingController _clientPostfix;
  ProgrammingLanguage _language = ProgrammingLanguage.dart;
  bool _isYaml = false;
  bool _freezed = false;
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
                  children: [
                    const Text(
                      'Config parameters',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 24),
                    StatefulBuilder(
                      builder: (context, setState) {
                        return DropdownButton<String>(
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
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    StatefulBuilder(
                      builder: (context, setState) {
                        return LabeledCheckbox(
                          label: 'Is YAML file content',
                          value: _isYaml,
                          onChanged: (newValue) {
                            setState(() {
                              _isYaml = newValue;
                            });
                          },
                        );
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
                    StatefulBuilder(
                      builder: (context, setState) {
                        return LabeledCheckbox(
                          label: 'Squish client folders into one?',
                          value: _squishClients,
                          onChanged: (newValue) {
                            setState(() {
                              _squishClients = newValue;
                            });
                          },
                        );
                      },
                    ),
                    if (_language == ProgrammingLanguage.dart) ...[
                      const SizedBox(height: 16),
                      StatefulBuilder(
                        builder: (context, setState) {
                          return LabeledCheckbox(
                            label: 'Use freezed?',
                            value: _freezed,
                            onChanged: (newValue) {
                              setState(() {
                                _freezed = newValue;
                              });
                            },
                          );
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
                            schema: _schemaController.text,
                            clientPostfix: _clientPostfix.text,
                            language: _language,
                            freezed: _freezed,
                            squishClients: _squishClients,
                            isYaml: _isYaml,
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
  required String schema,
  required String clientPostfix,
  required ProgrammingLanguage language,
  required bool freezed,
  required bool squishClients,
  required bool isYaml,
}) async {
  final generator = Generator.fromString(
    schemaContent: schema,
    language: language,
    clientPostfix: clientPostfix,
    freezed: freezed,
    squishClients: squishClients,
    isYaml: isYaml,
  );
  try {
    final files = await generator.generateContent();
    generateArchive(files);
  } on Object catch (e) {
    log(e.toString());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
