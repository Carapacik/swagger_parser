extension StringTypeX on String {
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
        switch (format) {
          case 'binary':
            return 'File';
          case 'date':
          case 'date-time':
            return 'DateTime';
        }
        return 'String';
      case 'file':
        return 'File';
      case 'boolean':
        return 'bool';
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
        switch (format) {
          case 'binary':
            return 'MultipartBody.Part';
          case 'date':
          case 'date-time':
            return 'Date';
        }
        return 'String';
      case 'file':
        return 'MultipartBody.Part';
      case 'boolean':
        return 'Boolean';
      case 'object':
        return 'Any';
    }
    return this;
  }

  String quoterForStringType({bool isDart = true}) => this == 'string'
      ? isDart
          ? "'"
          : '"'
      : '';
}
