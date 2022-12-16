extension StringTypeExt on String {
  String toDartType([String? format]) {
    switch (this) {
      case 'integer':
        return 'int';
      case 'number':
        if (format != null && (format == 'float' || format == 'double')) {
          return 'double';
        }
        // This can happen
        if (format != null && format == 'string') {
          return 'String';
        }
        return 'num';
      case 'string':
        if (format != null && format == 'binary') {
          // Single MultipartFile is not generated due an error
          return 'List<MultipartFile>';
        }
        return 'String';
      case 'boolean':
        return 'bool';
      case 'file':
        // Single MultipartFile is not generated due an error
        return 'List<MultipartFile>';
      case 'object':
        return 'Object';
    }
    return this;
  }

  String toKotlinType([String? format]) {
    switch (this) {
      case 'integer':
        return 'Int';
      case 'number':
        if (format != null && format == 'float') {
          return 'Float';
        }
        // This can happen
        if (format != null && format == 'string') {
          return 'String';
        }
        return 'Double';
      case 'string':
        if (format != null && format == 'binary') {
          return 'MultipartBody.Part';
        }
        return 'String';
      case 'boolean':
        return 'Boolean';
      case 'file':
        return 'MultipartBody.Part';
      case 'object':
        return 'Any?';
    }
    return this;
  }

  String quoterForStringType() => this == 'string' ? "'" : '';
}
