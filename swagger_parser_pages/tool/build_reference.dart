import 'dart:convert';
import 'dart:io';

import 'package:markdown/markdown.dart' as md;

/// Builds local references from the package documentation.
Future<void> buildReference(Directory output) async {
  const sources = {
    'configuration.html': '../swagger_parser/CONFIGURATION.md',
    'guide.html': '../swagger_parser/GUIDE.md',
    'templates.html': '../swagger_parser_templates/README.md',
    'template-context.html': '../swagger_parser_templates/CONTEXT.md',
  };
  for (final MapEntry<String, String> entry in sources.entries) {
    final source = File(entry.value);
    final document = md.Document(extensionSet: md.ExtensionSet.gitHubWeb);
    final List<md.Node> nodes = document.parseLines(await source.readAsLines());
    void rewrite(List<md.Node> nodes) {
      for (final md.Element node in nodes.whereType<md.Element>()) {
        if (node.tag == 'a' && node.attributes.containsKey('href')) {
          final String href = node.attributes['href']!;
          final Uri uri = Uri.parse(href);
          if (!uri.hasScheme && !href.startsWith('#')) {
            final resolved = source.uri
                .resolve(href)
                .normalizePath()
                .toString();
            final MapEntry<String, String>? local = sources.entries
                .where((e) => resolved.split('#').first == e.value)
                .firstOrNull;
            if (local != null) {
              node.attributes['href'] =
                  '${local.key}${uri.hasFragment ? '#${uri.fragment}' : ''}';
            } else {
              node.attributes['href'] =
                  'https://github.com/Carapacik/swagger_parser/blob/main/${resolved.replaceFirst('../', '')}';
              node.attributes['target'] = '_blank';
              node.attributes['rel'] = 'noopener';
            }
          }
        }
        if (node.children case final children?) {
          rewrite(children);
        }
      }
    }

    rewrite(nodes);
    final String title = const HtmlEscape().convert(
      nodes.whereType<md.Element>().first.textContent,
    );
    await File('${output.path}/${entry.key}').writeAsString('''
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$title</title>
<link rel="stylesheet" href="styles.css">
</head>
<body class="reference-document">
<nav aria-label="Reference pages"><a href="configuration.html">Configuration</a> · <a href="guide.html">Guide</a> · <a href="templates.html">Templates</a></nav>
<main>${md.renderToHtml(nodes)}</main>
</body>
</html>
''');
  }
}
