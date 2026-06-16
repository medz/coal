import 'event.dart';

typedef KeyBindingHandler = void Function(KeyEvent event);

/// Dispatches normalized key events to registered handlers.
final class KeyDispatcher {
  final _bindings = <String, List<KeyBindingHandler>>{};

  int get bindingCount {
    return _bindings.values.fold<int>(
      0,
      (count, handlers) => count + handlers.length,
    );
  }

  void bind(String binding, KeyBindingHandler handler, {bool replace = false}) {
    final normalized = normalizeKeyBinding(binding);
    final handlers = _bindings.putIfAbsent(
      normalized,
      () => <KeyBindingHandler>[],
    );
    if (replace) handlers.clear();
    handlers.add(handler);
  }

  bool unbind(String binding, [KeyBindingHandler? handler]) {
    final normalized = normalizeKeyBinding(binding);
    final handlers = _bindings[normalized];
    if (handlers == null || handlers.isEmpty) return false;

    if (handler == null) {
      _bindings.remove(normalized);
      return true;
    }

    final removed = handlers.remove(handler);
    if (handlers.isEmpty) _bindings.remove(normalized);
    return removed;
  }

  bool isBound(String binding) {
    return _bindings[normalizeKeyBinding(binding)]?.isNotEmpty == true;
  }

  bool dispatch(KeyEvent event) {
    final handlers = _bindings[event.binding];
    if (handlers == null || handlers.isEmpty) return false;

    for (final handler in List<KeyBindingHandler>.of(handlers)) {
      handler(event);
    }
    return true;
  }

  void clear() => _bindings.clear();
}
