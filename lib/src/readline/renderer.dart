import '../utils/cursor.dart';
import '../utils/erase.dart';
import '../utils/text_width.dart';
import 'line_buffer.dart';

final class LineRenderer {
  LineRenderer({
    required StringSink output,
    required String prompt,
    required int terminalColumns,
  }) : _output = output,
       _prompt = prompt,
       _terminalColumns = terminalColumns < 1 ? 1 : terminalColumns;

  final StringSink _output;
  final String _prompt;
  final int _terminalColumns;
  int _rows = 1;
  int _cursorRow = 0;

  void render(LineBuffer buffer) {
    final promptWidth = getTextWidth(_prompt).toInt();
    final lineWidth = promptWidth + buffer.width;
    final cursorCell = promptWidth + buffer.widthBeforeCursor;
    final rows = _rowsFor(lineWidth);
    var cursorRow = cursorCell ~/ _terminalColumns;
    var cursorColumn = cursorCell % _terminalColumns;
    if (cursorCell > 0 && cursorCell == lineWidth && cursorColumn == 0) {
      cursorRow -= 1;
      cursorColumn = _terminalColumns - 1;
    }

    _moveToRenderStart();
    _eraseRenderedRows();
    _output
      ..write(_prompt)
      ..write(buffer.text);

    _rows = rows;
    _cursorRow = cursorRow.clamp(0, rows - 1);
    _moveToRenderStart(fromRow: rows - 1);
    if (_cursorRow > 0) {
      _output.write(cursorDown(_cursorRow));
    }
    _output.write(cursorTo(cursorColumn));
  }

  void finishLine() {
    final remainingRows = _rows - _cursorRow - 1;
    if (remainingRows > 0) {
      _output.write(cursorDown(remainingRows));
    }
    _output.write('\n');
    _rows = 1;
    _cursorRow = 0;
  }

  int _rowsFor(int width) {
    return width <= 0 ? 1 : ((width - 1) ~/ _terminalColumns) + 1;
  }

  void _moveToRenderStart({int? fromRow}) {
    final row = fromRow ?? _cursorRow;
    if (row > 0) {
      _output.write(cursorUp(row));
    }
    _output.write(cursorLeft);
  }

  void _eraseRenderedRows() {
    for (var row = 0; row < _rows; row++) {
      _output.write(eraseLine);
      if (row < _rows - 1) {
        _output.write(cursorDown());
      }
    }
    if (_rows > 1) {
      _output.write(cursorUp(_rows - 1));
    }
    _output.write(cursorLeft);
  }
}
