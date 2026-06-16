import '../keypass/event.dart';
import 'history.dart';
import 'line_buffer.dart';

enum LineEditAction { none, changed, submitted, canceled, eof }

/// Result of applying one input to a [LineEditor].
final class LineEditResult {
  const LineEditResult(this.action, {this.value});

  const LineEditResult.none() : this(LineEditAction.none);

  const LineEditResult.changed(String value)
    : this(LineEditAction.changed, value: value);

  const LineEditResult.submitted(String value)
    : this(LineEditAction.submitted, value: value);

  const LineEditResult.canceled(String value)
    : this(LineEditAction.canceled, value: value);

  const LineEditResult.eof() : this(LineEditAction.eof);

  final LineEditAction action;
  final String? value;

  bool get isTerminal {
    return action == LineEditAction.submitted ||
        action == LineEditAction.canceled ||
        action == LineEditAction.eof;
  }
}

/// Editing core for one readline-style input line.
final class LineEditor {
  LineEditor({LineBuffer? buffer, LineHistory? history})
    : buffer = buffer ?? LineBuffer(),
      history = history ?? LineHistory();

  final LineBuffer buffer;
  final LineHistory history;

  int? _historyIndex;
  var _historyDraft = '';

  String get text => buffer.text;

  int get cursor => buffer.cursor;

  LineEditResult apply(KeyInput input) {
    return switch (input) {
      TextInput(:final text) => _insert(text),
      KeyEvent() => _applyKey(input),
    };
  }

  LineEditResult submit() {
    final value = buffer.text;
    history.add(value);
    buffer.clear();
    _resetHistoryCursor();
    return LineEditResult.submitted(value);
  }

  LineEditResult cancel() {
    final value = buffer.text;
    buffer.clear();
    _resetHistoryCursor();
    return LineEditResult.canceled(value);
  }

  LineEditResult _insert(String text) {
    _resetHistoryCursor();
    return _changed(buffer.insert(text));
  }

  LineEditResult _applyKey(KeyEvent event) {
    switch (event.binding) {
      case 'enter':
        return submit();
      case 'ctrl+c':
        return cancel();
      case 'ctrl+d':
        if (buffer.isEmpty) return const LineEditResult.eof();
        _resetHistoryCursor();
        return _changed(buffer.deleteForward());
      case 'backspace':
      case 'ctrl+h':
        _resetHistoryCursor();
        return _changed(buffer.deleteBackward());
      case 'delete':
        _resetHistoryCursor();
        return _changed(buffer.deleteForward());
      case 'left':
      case 'ctrl+b':
        return _changed(buffer.moveLeft());
      case 'right':
      case 'ctrl+f':
        return _changed(buffer.moveRight());
      case 'home':
      case 'ctrl+a':
        return _changed(buffer.moveToStart());
      case 'end':
      case 'ctrl+e':
        return _changed(buffer.moveToEnd());
      case 'ctrl+u':
        _resetHistoryCursor();
        return _changed(buffer.clearBeforeCursor());
      case 'ctrl+k':
        _resetHistoryCursor();
        return _changed(buffer.clearAfterCursor());
      case 'up':
      case 'ctrl+p':
        return _changed(_historyPrevious());
      case 'down':
      case 'ctrl+n':
        return _changed(_historyNext());
    }

    return const LineEditResult.none();
  }

  LineEditResult _changed(bool changed) {
    if (!changed) return const LineEditResult.none();
    return LineEditResult.changed(buffer.text);
  }

  bool _historyPrevious() {
    if (history.isEmpty) return false;

    if (_historyIndex == null) {
      _historyDraft = buffer.text;
      _historyIndex = history.length - 1;
    } else if (_historyIndex! > 0) {
      _historyIndex = _historyIndex! - 1;
    } else {
      return false;
    }

    buffer.replace(history[_historyIndex!]);
    return true;
  }

  bool _historyNext() {
    final index = _historyIndex;
    if (index == null) return false;

    if (index < history.length - 1) {
      _historyIndex = index + 1;
      buffer.replace(history[_historyIndex!]);
    } else {
      _historyIndex = null;
      buffer.replace(_historyDraft);
      _historyDraft = '';
    }

    return true;
  }

  void _resetHistoryCursor() {
    _historyIndex = null;
    _historyDraft = '';
  }
}
