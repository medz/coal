import 'decoder.dart';
import 'dispatcher.dart';
import 'event.dart';

/// Convenience facade that parses key bytes and dispatches key events.
final class Keypass {
  Keypass({KeyParser? parser, KeyDispatcher? dispatcher})
    : parser = parser ?? KeyParser(),
      dispatcher = dispatcher ?? KeyDispatcher();

  final KeyParser parser;
  final KeyDispatcher dispatcher;

  int get bindingCount => dispatcher.bindingCount;

  void bind(String binding, KeyBindingHandler handler, {bool replace = false}) {
    dispatcher.bind(binding, handler, replace: replace);
  }

  bool unbind(String binding, [KeyBindingHandler? handler]) {
    return dispatcher.unbind(binding, handler);
  }

  bool isBound(String binding) => dispatcher.isBound(binding);

  bool dispatch(KeyEvent event) => dispatcher.dispatch(event);

  List<KeyInput> addBytes(List<int> bytes) {
    return _dispatchParsed(parser.addBytes(bytes));
  }

  List<KeyInput> addString(String input) {
    return _dispatchParsed(parser.addString(input));
  }

  List<KeyInput> flush() {
    return _dispatchParsed(parser.flush());
  }

  List<KeyInput> close() {
    return _dispatchParsed(parser.close());
  }

  void clear() => dispatcher.clear();

  List<KeyInput> _dispatchParsed(List<KeyInput> inputs) {
    for (final input in inputs) {
      if (input is KeyEvent) dispatcher.dispatch(input);
    }
    return inputs;
  }
}
