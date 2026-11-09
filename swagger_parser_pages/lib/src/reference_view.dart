import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:http/http.dart' as http;
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:web/web.dart' as web;

/// Displays built package documentation in the page scroll flow.
class const ReferenceView({
  /// URL of the trusted, locally built reference page.
  required final String source,
}) extends StatefulComponent {
  /// Creates the reference reader.
  this;

  @override
  State<ReferenceView> createState() => _ReferenceViewState();
}

class _ReferenceViewState() extends State<ReferenceView> {
  String? _html;
  String? _error;
  int _request = 0;
  late Uri _base;

  @override
  void initState() {
    super.initState();
    _base = Uri.base.resolve(component.source);
    unawaited(_load(_base));
  }

  Future<void> _load(Uri uri) async {
    final int request = ++_request;
    setState(() {
      _error = null;
      _html = null;
    });
    try {
      final http.Response response = await http.get(uri.removeFragment());
      if (response.statusCode != 200) {
        throw const FormatException('Cannot load the reference. Try again.');
      }
      final web.Document document = web.DOMParser().parseFromString(
        utf8.decode(response.bodyBytes).toJS,
        'text/html',
      );
      final web.Element? content = document.querySelector('main');
      if (content == null) {
        throw const FormatException('Reference content is missing.');
      }
      if (!mounted || request != _request) {
        return;
      }
      // Only the built package reference is rendered as HTML, never editor input.
      setState(() => _html = content.innerHTML.toString());
      if (uri.hasFragment) {
        await Future<void>.delayed(Duration.zero);
        if (mounted && request == _request) {
          web.document.getElementById(uri.fragment)?.scrollIntoView();
        }
      }
    } on Object catch (error) {
      if (mounted && request == _request) {
        setState(() => _error = error.toString());
      }
    }
  }

  void _click(web.MouseEvent event) {
    if (event.button != 0 ||
        event.ctrlKey ||
        event.metaKey ||
        event.shiftKey ||
        event.altKey) {
      return;
    }
    final web.EventTarget? target = event.target;
    if (target == null) {
      return;
    }
    final web.Element? link = (target as web.Element).closest('a');
    final String? href = link?.getAttribute('href');
    if (href == null) {
      return;
    }
    if (href.startsWith('#')) {
      event.preventDefault();
      web.document
          .getElementById(Uri.decodeComponent(href.substring(1)))
          ?.scrollIntoView();
      return;
    }
    final Uri uri = _base.resolve(href);
    if (uri.origin == _base.origin &&
        [
          'configuration.html',
          'guide.html',
          'templates.html',
        ].contains(uri.pathSegments.last)) {
      event.preventDefault();
      unawaited(_load(uri));
    }
  }

  @override
  Component build(BuildContext context) => div(
    id: 'reference-content',
    classes: 'reference-document',
    events: {'click': (event) => _click(event as web.MouseEvent)},
    [
      nav(
        attributes: const {'aria-label': 'Reference pages'},
        [
          for (final entry in {
            'configuration.html': 'Configuration',
            'guide.html': 'Guide',
            'templates.html': 'Templates',
          }.entries)
            a(href: _base.resolve(entry.key).toString(), [
              Component.text(entry.value),
            ]),
        ],
      ),
      if (_error case final error?) ...[
        p(attributes: const {'role': 'alert'}, [Component.text(error)]),
        button(onClick: () => _load(_base), const [Component.text('Retry')]),
      ] else if (_html case final html?)
        RawText(html)
      else
        const p(
          attributes: {'role': 'status'},
          [Component.text('Loading reference…')],
        ),
    ],
  );
}
