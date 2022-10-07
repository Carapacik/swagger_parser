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
  final TextEditingController _jsonController = TextEditingController();
  final TextEditingController _clientPostfix = TextEditingController();
  bool _isFreezed = false;
  bool _squishClients = false;
  ProgrammingLanguage _language = ProgrammingLanguage.dart;

  @override
  void dispose() {
    _jsonController.dispose();
    _clientPostfix.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          children: [
            SizedBox(
              height: 400,
              width: 400,
              child: TextField(
                controller: _jsonController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Paste your Swagger JSON here',
                  hintStyle: TextStyle(fontSize: 18),
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
        Column(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              width: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Change config parameters',
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.grey,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 30),
                  ButtonTheme(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                    ),
                    child: DropdownButton<String>(
                      value: _language.name,
                      style: const TextStyle(fontSize: 24),
                      isExpanded: true,
                      icon: const RotatedBox(
                        quarterTurns: 1,
                        child: Icon(Icons.arrow_forward_ios_sharp),
                      ),
                      underline: const SizedBox.shrink(),
                      elevation: 16,
                      onChanged: (value) {
                        setState(() {
                          _language = ProgrammingLanguage.fromString(
                            value,
                          )!;
                        });
                      },
                      items: ProgrammingLanguage.values
                          .map<DropdownMenuItem<String>>((value) {
                        return DropdownMenuItem<String>(
                          value: value.name,
                          child: Text(value.name),
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(),
                  TextField(
                    controller: _clientPostfix,
                    decoration: const InputDecoration(
                      labelStyle: TextStyle(fontSize: 24),
                      hintText: 'Postfix for client files',
                      hintStyle: TextStyle(fontSize: 24),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(fontSize: 24),
                  ),
                  const Divider(),
                  LabeledCheckbox(
                    label: 'Squish client folders into one?',
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    value: _squishClients,
                    onChanged: (newValue) {
                      setState(() {
                        _squishClients = newValue;
                      });
                    },
                  ),
                  if (_language == ProgrammingLanguage.dart) ...<Widget>[
                    const Divider(),
                    LabeledCheckbox(
                      label: 'Use freezed?',
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      value: _isFreezed,
                      onChanged: (newValue) {
                        setState(() {
                          _isFreezed = newValue;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 300,
              height: 40,
              child: ElevatedButton(
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
                  );
                },
              ),
            ),
          ],
        )
      ],
    );
  }
}

Future<void> generateOutputs(
  BuildContext context, {
  required String json,
  required String clientPostfix,
  required ProgrammingLanguage language,
  required bool useFreezed,
  required bool squishClients,
}) async {
  final generator = Generator.fromString(
    jsonContent: json,
    language: language,
    clientPostfix: clientPostfix,
    freezed: useFreezed,
    squishClients: squishClients,
  );
  try {
    final files = await generator.generateContent();
    generateArchive(files);
  } on Object catch (e) {
    debugPrint(e.toString());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString()),
      ),
    );
  }
}
