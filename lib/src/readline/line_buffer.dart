import 'package:characters/characters.dart';

import '../utils/text_width.dart';

final class LineBuffer {
  final List<String> _chars = <String>[];

  int cursor = 0;

  bool get isEmpty => _chars.isEmpty;

  String get text => _chars.join();

  String get beforeCursor => _chars.take(cursor).join();

  int get width => getTextWidth(text).toInt();

  int get widthBeforeCursor => getTextWidth(beforeCursor).toInt();

  void replace(String value) {
    _chars
      ..clear()
      ..addAll(value.characters);
    cursor = _chars.length;
  }

  void insert(String value) {
    for (final char in value.characters) {
      _chars.insert(cursor, char);
      cursor += 1;
    }
  }

  bool deleteBeforeCursor() {
    if (cursor == 0) return false;
    _chars.removeAt(cursor - 1);
    cursor -= 1;
    return true;
  }

  bool deleteAtCursor() {
    if (cursor >= _chars.length) return false;
    _chars.removeAt(cursor);
    return true;
  }

  bool clearBeforeCursor() {
    if (cursor == 0) return false;
    _chars.removeRange(0, cursor);
    cursor = 0;
    return true;
  }

  bool clearAfterCursor() {
    if (cursor >= _chars.length) return false;
    _chars.removeRange(cursor, _chars.length);
    return true;
  }

  bool moveLeft() {
    if (cursor == 0) return false;
    cursor -= 1;
    return true;
  }

  bool moveRight() {
    if (cursor >= _chars.length) return false;
    cursor += 1;
    return true;
  }

  bool moveHome() {
    if (cursor == 0) return false;
    cursor = 0;
    return true;
  }

  bool moveEnd() {
    if (cursor == _chars.length) return false;
    cursor = _chars.length;
    return true;
  }
}
