import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';

/// Explains what Swagger Parser generates and how to use the web interface.
class const InformationBox({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('This is the browser interface for '),
              _PackageLink(
                label: 'swagger_parser',
                uri: Uri.parse('https://pub.dev/packages/swagger_parser'),
              ),
              const Text(
                '. It generates Dart or Kotlin REST clients and data classes '
                'directly from an OpenAPI YAML or JSON document.',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('How to use it', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            '1. Choose a schema file or paste its contents.\n'
            '2. Select YAML or JSON and configure the generator.\n'
            '3. Generate and download the resulting ZIP archive.',
          ),
          const SizedBox(height: 20),
          Text(
            'Available configuration',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'The form exposes every generation option from SWPConfig, including '
            'serializers, client/output merging, enum behavior, Retrofit options, '
            'tag and path filtering, replacement rules, field parsers, nullable '
            'handling, Flutter compute, and URL constants.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Lists accept comma-separated or line-separated values. Replacement '
            'rules use “pattern => replacement”. Field parsers use '
            '“Type | parserName | importPath”, one entry per line.',
          ),
        ],
      ),
    ),
  );
}

class const _PackageLink({required final String label, required final Uri uri})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Link(
    uri: uri,
    builder: (context, followLink) =>
        TextButton(onPressed: followLink, child: Text(label)),
  );
}
