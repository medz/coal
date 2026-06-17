import 'key_binding.dart';
import 'key_event.dart';

/// Handles a decoded key event.
typedef KeyHandler = void Function(KeyEvent event);

/// Key binding dispatcher for terminal flows.
///
/// [Keypass] operates on complete terminal key sequences. It does not read from
/// stdin or buffer byte chunks; higher-level input modules can own that state.
final class Keypass {
  final Map<String, List<KeyHandler>> _handlers = {};

  /// Registers [handler] for [binding].
  ///
  /// Bindings are normalized before storage, so `Ctrl + C` and `ctrl+c` match
  /// the same key event.
  void bind(String binding, KeyHandler handler) {
    final normalized = normalizeKeyBinding(binding);
    _handlers.putIfAbsent(normalized, () => <KeyHandler>[]).add(handler);
  }

  /// Removes all handlers for [binding].
  ///
  /// Returns `true` when a binding existed.
  bool unbind(String binding) {
    final normalized = normalizeKeyBinding(binding);
    return _handlers.remove(normalized) != null;
  }

  /// Removes all bindings.
  void clear() => _handlers.clear();

  /// Dispatches [event] to matching handlers.
  ///
  /// Returns `true` when at least one handler matched. The current handler list
  /// is copied before dispatch, so handlers can safely mutate bindings without
  /// affecting the in-flight dispatch.
  bool dispatch(KeyEvent event) {
    final handlers = _handlers[event.binding];
    if (handlers == null || handlers.isEmpty) return false;

    for (final handler in List<KeyHandler>.from(handlers)) {
      handler(event);
    }
    return true;
  }

  /// Decodes and dispatches a complete terminal key [sequence].
  bool handleSequence(String sequence) =>
      dispatch(KeyEvent.fromSequence(sequence));
}
