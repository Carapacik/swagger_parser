import 'dart:js_interop';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:swagger_parser_pages/src/generator_editor.dart';
import 'package:swagger_parser_pages/src/page_routes.dart';
import 'package:swagger_parser_pages/src/reference_view.dart';
import 'package:web/web.dart' as web;

/// Generator, local configuration reference, and template workspaces.
class const App({
  super.key,

  /// Worker script URL, relative to the current page by default.
  final String workerUrl = 'worker.dart.js',

  /// Local reference URL, relative to the current page by default.
  final String referenceUrl = 'configuration.html',

  /// Static hosting root, with leading and trailing slashes.
  final String basePath = '/',
}) extends StatefulComponent {
  /// Creates the browser application.
  this;

  @override
  State<App> createState() => _AppState();
}

class _AppState() extends State<App> {
  String _active = 'generator';
  final Set<String> _visited = {'generator'};
  static const Map<String, String> _tabs = PageRoutes.tabs;
  late PageRoutes _routes;
  late JSFunction _popState;

  @override
  void initState() {
    super.initState();
    _routes = PageRoutes(component.basePath);
    _active = _routes.tab(web.window.location.pathname);
    _visited.add(_active);
    _popState = ((web.Event event) {
      _select(_routes.tab(web.window.location.pathname), push: false);
    }).toJS;
    web.window.addEventListener('popstate', _popState);
    final String path = _routes.path(_active);
    if (web.window.location.pathname != path) {
      web.window.history.replaceState(
        null,
        '',
        '$path${web.window.location.search}${web.window.location.hash}',
      );
    }
  }

  @override
  void dispose() {
    web.window.removeEventListener('popstate', _popState);
    super.dispose();
  }

  void _select(String tab, {bool push = true}) {
    if (push && web.window.location.pathname != _routes.path(tab)) {
      web.window.history.pushState(null, '', _routes.path(tab));
    }
    setState(() {
      _active = tab;
      _visited.add(tab);
    });
  }

  void _navigate(String tab, web.MouseEvent event) {
    if (event.button != 0 ||
        event.ctrlKey ||
        event.metaKey ||
        event.shiftKey ||
        event.altKey) {
      return;
    }
    event.preventDefault();
    _select(tab);
  }

  void _key(String current, web.KeyboardEvent event) {
    final List<String> tabs = _tabs.keys.toList();
    final int index = tabs.indexOf(current);
    final String? next = switch (event.key) {
      'ArrowRight' => tabs[(index + 1) % tabs.length],
      'ArrowLeft' => tabs[(index + tabs.length - 1) % tabs.length],
      'Home' => tabs.first,
      'End' => tabs.last,
      _ => null,
    };
    if (next != null) {
      event.preventDefault();
      _select(next);
      (web.document.getElementById('tab-$next')! as web.HTMLElement).focus();
    }
  }

  @override
  Component build(BuildContext context) => div(classes: 'site', [
    header(classes: 'site-header', [
      a(
        id: 'home-link',
        href: _routes.path('generator'),
        classes: 'brand',
        events: {
          'click': (event) => _navigate('generator', event as web.MouseEvent),
        },
        [
          img(
            src: '${component.basePath}favicon.svg',
            classes: 'brand-mark',
            alt: '',
          ),
          const Component.text('swagger_parser'),
        ],
      ),
      div(
        classes: 'site-tabs',
        attributes: const {'role': 'tablist', 'aria-label': 'Workspace'},
        [
          for (final entry in _tabs.entries)
            a(
              href: _routes.path(entry.key),
              id: 'tab-${entry.key}',
              classes: _active == entry.key ? 'active' : '',
              attributes: {
                'role': 'tab',
                'aria-selected': '${_active == entry.key}',
                'aria-controls': 'panel-${entry.key}',
                'tabindex': _active == entry.key ? '0' : '-1',
              },
              events: {
                'click': (event) =>
                    _navigate(entry.key, event as web.MouseEvent),
                'keydown': (event) =>
                    _key(entry.key, event as web.KeyboardEvent),
              },
              [Component.text(entry.value)],
            ),
        ],
      ),
      a(
        href: 'https://github.com/Carapacik/swagger_parser',
        classes: 'github-link',
        attributes: const {
          'aria-label': 'GitHub repository',
          'title': 'GitHub',
        },
        [
          img(
            src: '${component.basePath}github.svg',
            alt: '',
            classes: 'github-icon',
          ),
        ],
      ),
    ]),
    for (final tab in _tabs.keys)
      div(
        key: ValueKey(tab),
        id: 'panel-$tab',
        attributes: {
          'role': 'tabpanel',
          'aria-labelledby': 'tab-$tab',
          if (_active != tab) 'hidden': '',
        },
        [
          if (_visited.contains(tab))
            if (tab == 'configuration')
              section(classes: 'reference-panel', [
                const h1([Component.text('Configuration')]),
                const p(classes: 'hero-copy', [
                  Component.text(
                    'Defaults, examples, and interactions. This reference includes CLI options. In the browser, paste one schema; input paths and output folders do not apply. Use the Templates tab for inline template sources.',
                  ),
                ]),
                ReferenceView(source: component.referenceUrl),
              ])
            else
              GeneratorEditor(
                key: ValueKey(tab),
                workerUrl: component.workerUrl,
                templates: tab == 'templates',
              ),
        ],
      ),
    const footer(classes: 'site-footer', [
      span([Component.text('swagger_parser')]),
      a(href: 'https://carapacik.github.io/', [
        Component.text('Carapacik Space ↗'),
      ]),
    ]),
  ]);
}
