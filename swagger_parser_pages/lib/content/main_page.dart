import 'package:flutter/material.dart';
import 'package:swagger_parser_pages/content/generator_content.dart';
import 'package:swagger_parser_pages/content/information_box.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16),
                Text(
                  'Swagger parser',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 8),
                Text(
                  'Paste your OpenApi JSON or YAML file content in the textarea below, '
                  'click "Generate and download" and get your generated files in zip archive.',
                  style: TextStyle(fontSize: 20, color: Colors.grey),
                ),
                SizedBox(height: 24),
                GeneratorContent(),
                SizedBox(height: 24),
                InformationBox(),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
