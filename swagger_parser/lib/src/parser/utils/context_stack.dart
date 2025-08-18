/// A stack-based context manager for tracking parsing contexts
///
/// This class ensures that contexts are properly managed during parsing,
/// with automatic cleanup and support for nested contexts.
class ContextStack {
  final List<String> _stack = [];

  /// Get the current context, or null if the stack is empty
  String? get current => _stack.isEmpty ? null : _stack.last;

  /// Get the full context path (useful for debugging)
  List<String> get path => List.unmodifiable(_stack);

  /// Check if we're currently in a context
  bool get hasContext => _stack.isNotEmpty;

  /// Execute an action within a specific context
  ///
  /// This method ensures the context is properly pushed before the action
  /// and popped after, even if an exception occurs.
  T withContext<T>(String context, T Function() action) {
    _stack.add(context);
    try {
      return action();
    } finally {
      _stack.removeLast();
    }
  }

  /// Execute an async action within a specific context
  Future<T> withContextAsync<T>(
      String context, Future<T> Function() action) async {
    _stack.add(context);
    try {
      return await action();
    } finally {
      _stack.removeLast();
    }
  }

  /// Push a context onto the stack
  ///
  /// Note: Prefer using withContext() for automatic cleanup
  void push(String context) {
    _stack.add(context);
  }

  /// Pop a context from the stack
  ///
  /// Note: Prefer using withContext() for automatic cleanup
  void pop() {
    if (_stack.isEmpty) {
      throw StateError('Cannot pop from empty context stack');
    }
    _stack.removeLast();
  }

  /// Clear all contexts
  void clear() {
    _stack.clear();
  }

  @override
  String toString() => 'ContextStack(${_stack.join(' > ')})';
}
