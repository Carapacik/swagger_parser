import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class InformationBox extends StatelessWidget {
  const InformationBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text.rich(
          TextSpan(
            text: 'What is this?\n',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            children: [
              TextSpan(
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
                text: 'This is a web showcase of ',
                children: [
                  TextSpan(
                    text: 'swagger_parser',
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        await launchUrl(
                          Uri.parse(
                            'https://pub.dev/packages/swagger_parser',
                          ),
                        );
                      },
                  ),
                  const TextSpan(
                    text:
                        '. Swagger parser allows you to generate Data classes and Rest clients from swagger json string.\n',
                  ),
                ],
              ),
              const WidgetSpan(
                alignment: PlaceholderAlignment.aboveBaseline,
                baseline: TextBaseline.alphabetic,
                child: SizedBox(height: 40),
              ),
              const TextSpan(
                text: 'Why do i need it?\n',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                children: [
                  TextSpan(
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
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
                text: 'How do I use it?\n',
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                children: [
                  TextSpan(
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                    ),
                    text:
                        'Paste your JSON file into text box and configure given parameters: \n',
                    children: [
                      const WidgetSpan(
                        alignment: PlaceholderAlignment.aboveBaseline,
                        baseline: TextBaseline.alphabetic,
                        child: SizedBox(height: 25),
                      ),
                      const TextSpan(
                        text:
                            '- Language parameter for generated files. Currently support languages are: dart, kotlin.\n',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const WidgetSpan(
                        alignment: PlaceholderAlignment.aboveBaseline,
                        baseline: TextBaseline.alphabetic,
                        child: SizedBox(height: 25),
                      ),
                      const TextSpan(
                        text:
                            '- Client class postfix. Works only if squish client folder is checked or if a single client class will be generated.\n',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const WidgetSpan(
                        alignment: PlaceholderAlignment.aboveBaseline,
                        baseline: TextBaseline.alphabetic,
                        child: SizedBox(height: 25),
                      ),
                      const TextSpan(
                        text:
                            '- Squish clients. By default, swagger parser will separate clients into different folders judging by tags. By checking this parameter you can instead put all clients into single folder.\n',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const WidgetSpan(
                        alignment: PlaceholderAlignment.aboveBaseline,
                        baseline: TextBaseline.alphabetic,
                        child: SizedBox(height: 25),
                      ),
                      TextSpan(
                        text:
                            "- Freezed. Available only for dart. Makes generated DTO's compatible with ",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                        ),
                        children: [
                          TextSpan(
                            text: 'freezed.\n',
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () async {
                                await launchUrl(
                                  Uri.parse('https://pub.dev/packages/freezed'),
                                );
                              },
                          ),
                        ],
                      ),
                      const WidgetSpan(
                        alignment: PlaceholderAlignment.aboveBaseline,
                        baseline: TextBaseline.alphabetic,
                        child: SizedBox(height: 25),
                      ),
                      const TextSpan(
                        text:
                            'Press generate and enjoy your Data classes packed into zip archive.',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
