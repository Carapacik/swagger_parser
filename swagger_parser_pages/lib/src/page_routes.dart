/// Page routes relative to a static hosting base path.
final class const PageRoutes(
  /// Hosting root, with leading and trailing slashes.
  final String basePath,
) {
  /// Creates the page route mapping.
  this;

  /// Header order and labels.
  static const tabs = {
    'generator': 'Generator',
    'templates': 'Templates',
    'configuration': 'Configuration',
  };

  /// Returns a route for an editor tab.
  String path(String tab) =>
      '$basePath${switch (tab) {
        'templates' => 'template',
        'configuration' => 'config',
        _ => '',
      }}';

  /// Reads a route. Directory index URLs select the same page.
  String tab(String pathname) {
    for (final String tab in tabs.keys) {
      final String route = path(tab);
      if (pathname == route ||
          pathname == '$route/' ||
          pathname == '${route.endsWith('/') ? route : '$route/'}index.html') {
        return tab;
      }
    }
    return 'generator';
  }
}
