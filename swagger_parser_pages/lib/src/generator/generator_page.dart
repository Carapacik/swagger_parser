import 'package:flutter/material.dart';
import 'package:swagger_parser_pages/src/generator/generator_content.dart';
import 'package:swagger_parser_pages/src/generator/information_box.dart';

class const GeneratorPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: SelectionArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'Swagger Parser',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Generate REST clients and data classes from an OpenAPI '
                    'YAML or JSON document, entirely in your browser.',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  const GeneratorContent(),
                  const SizedBox(height: 24),
                  const InformationBox(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
