import 'package:characters/characters.dart';

/// Editable line state with a cursor measured in user-visible characters.
final class LineBuffer {
  LineBuffer([String text = '']) : _chars = text.characters.toList() {
    _cursor = _chars.length;
  }

  final List<String> _chars;
  var _cursor = 0;

  String get text => _chars.join();

  int get length => _chars.length;

  bool get isEmpty => _chars.isEmpty;

  int get cursor => _cursor;

  set cursor(int value) {
    _cursor = value.clamp(0, _chars.length);
  }

  void replace(String text, {int? cursor}) {
    _chars
      ..clear()
      ..addAll(text.characters);
    this.cursor = cursor ?? _chars.length;
  }

  bool insert(String text) {
    if (text.isEmpty) return false;
    final input = text.characters.toList();
    if (input.isEmpty) return false;
    _chars.insertAll(_cursor, input);
    _cursor += input.length;
    return true;
  }

  bool deleteBackward() {
    if (_cursor == 0) return false;
    _chars.removeAt(_cursor - 1);
    _cursor--;
    return true;
  }

  bool deleteForward() {
    if (_cursor >= _chars.length) return false;
    _chars.removeAt(_cursor);
    return true;
  }

  bool clearBeforeCursor() {
    if (_cursor == 0) return false;
    _chars.removeRange(0, _cursor);
    _cursor = 0;
    return true;
  }

  bool clearAfterCursor() {
    if (_cursor >= _chars.length) return false;
    _chars.removeRange(_cursor, _chars.length);
    return true;
  }

  bool moveLeft([int count = 1]) {
    if (count <= 0) return false;
    final previous = _cursor;
    cursor = _cursor - count;
    return _cursor != previous;
  }

  bool moveRight([int count = 1]) {
    if (count <= 0) return false;
    final previous = _cursor;
    cursor = _cursor + count;
    return _cursor != previous;
  }

  bool moveToStart() {
    final previous = _cursor;
    _cursor = 0;
    return previous != _cursor;
  }

  bool moveToEnd() {
    final previous = _cursor;
    _cursor = _chars.length;
    return previous != _cursor;
  }

  void clear() {
    _chars.clear();
    _cursor = 0;
  }

  @override
  String toString() => 'LineBuffer(text: $text, cursor: $_cursor)';
}
