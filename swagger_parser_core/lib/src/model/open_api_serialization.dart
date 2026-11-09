/// How a parameter is serialized in a request.
enum OpenApiParameterStyle() {
  /// Prefix a path parameter with a semicolon.
  matrix,

  /// Prefix a path parameter with a period.
  label,

  /// Use form-style query or cookie parameters.
  form,

  /// Use comma-separated path or header values.
  simple,

  /// Separate query values with spaces.
  spaceDelimited,

  /// Separate query values with vertical bars.
  pipeDelimited,

  /// Use bracketed property names in a query object.
  deepObject,
}

/// The part of the request that carries a parameter.
enum OpenApiParameterLocation() {
  /// In the URL query string.
  query,

  /// In an HTTP request header.
  header,

  /// In a URL path template.
  path,

  /// In a request cookie.
  cookie,
}
