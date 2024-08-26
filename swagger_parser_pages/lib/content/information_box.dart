import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';

class InformationBox extends StatelessWidget {
  const InformationBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: 'What is this?\n',
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        children: [
          TextSpan(
            style: const TextStyle(fontSize: 18),
            text: 'This is a web showcase of ',
            children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: Link(
                  uri: Uri.parse('https://pub.dev/packages/swagger_parser'),
                  builder: (context, followLink) => MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: followLink,
                      child: const Text(
                        'swagger_parser',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFFD0BCFF),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const TextSpan(
                text:
                    '. Swagger parser allows you to generate Data classes and Rest clients from OpenApi YAML or JSON definition file content.\n',
              ),
            ],
          ),
          const WidgetSpan(
            alignment: PlaceholderAlignment.aboveBaseline,
            baseline: TextBaseline.alphabetic,
            child: SizedBox(height: 40),
          ),
          const TextSpan(
            text: 'Why do you need it?\n',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            children: [
              TextSpan(
                style: TextStyle(fontSize: 18),
                text:
                    'Swagger parser allows you to save time by generating all classes that you would have to otherwise write by hand.\n',
              ),
            ],
          ),
          const WidgetSpan(
            alignment: PlaceholderAlignment.aboveBaseline,
            baseline: TextBaseline.alphabetic,
            child: SizedBox(height: 40),
          ),
          TextSpan(
            text: 'How do you use it?\n',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            children: [
              TextSpan(
                style: const TextStyle(fontSize: 18),
                text:
                    'Paste your JSON file into text box and configure given parameters: \n',
                children: [
                  const WidgetSpan(
                    alignment: PlaceholderAlignment.aboveBaseline,
                    baseline: TextBaseline.alphabetic,
                    child: SizedBox(height: 24),
                  ),
                  const TextSpan(
                    text:
                        '- Client class postfix. Works only if squish client folder is checked or if a single client class will be generated.\n',
                    style: TextStyle(fontSize: 18),
                  ),
                  const WidgetSpan(
                    alignment: PlaceholderAlignment.aboveBaseline,
                    baseline: TextBaseline.alphabetic,
                    child: SizedBox(height: 24),
                  ),
                  const WidgetSpan(
                    alignment: PlaceholderAlignment.aboveBaseline,
                    baseline: TextBaseline.alphabetic,
                    child: SizedBox(height: 24),
                  ),
                  const TextSpan(
                    text:
                        '- Language parameter for generated files. Currently support languages are: dart, kotlin.\n',
                    style: TextStyle(fontSize: 18),
                  ),
                  const TextSpan(
                    text:
                        '- Put clients in folder. By default, swagger parser will separate clients into different folders judging by tags. By checking this parameter you can instead put all clients into single folder.\n',
                    style: TextStyle(fontSize: 18),
                  ),
                  const WidgetSpan(
                    alignment: PlaceholderAlignment.aboveBaseline,
                    baseline: TextBaseline.alphabetic,
                    child: SizedBox(height: 24),
                  ),
                  TextSpan(
                    text:
                        '- Freezed. Available only for dart. Makes generated DTOs compatible with ',
                    style: const TextStyle(fontSize: 18),
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: Link(
                          uri: Uri.parse('https://pub.dev/packages/freezed'),
                          builder: (context, followLink) => MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: followLink,
                              child: const Text(
                                'freezed',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFFD0BCFF),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const TextSpan(
                    text:
                        '\nPress generate and enjoy your Data classes and Rest clients packed into zip archive.',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
