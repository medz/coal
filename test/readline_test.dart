import 'package:coal/keypass.dart';
import 'package:coal/readline.dart';
import 'package:test/test.dart';

void main() {
  group('line buffer', () {
    test('edits text around the cursor', () {
      final buffer = LineBuffer('coal');

      expect(buffer.moveLeft(), isTrue);
      expect(buffer.insert('!'), isTrue);
      expect(buffer.text, 'coa!l');
      expect(buffer.cursor, 4);

      expect(buffer.deleteBackward(), isTrue);
      expect(buffer.deleteForward(), isTrue);
      expect(buffer.text, 'coa');
      expect(buffer.moveToStart(), isTrue);
      expect(buffer.insert('hot '), isTrue);
      expect(buffer.text, 'hot coa');
    });

    test('measures cursor by grapheme clusters', () {
      final buffer = LineBuffer('a👩‍💻b');

      expect(buffer.length, 3);
      expect(buffer.moveLeft(2), isTrue);
      expect(buffer.insert('x'), isTrue);
      expect(buffer.text, 'ax👩‍💻b');
      expect(buffer.cursor, 2);
      expect(buffer.moveLeft(0), isFalse);
      expect(buffer.moveRight(-1), isFalse);
    });
  });

  group('line history', () {
    test('limits entries and skips empty and adjacent duplicates', () {
      final history = LineHistory(limit: 2);

      history
        ..add('')
        ..add('one')
        ..add('one')
        ..add('two')
        ..add('three');

      expect(history.entries, <String>['two', 'three']);
    });

    test('rejects negative limits', () {
      expect(() => LineHistory(limit: -1), throwsArgumentError);
    });
  });

  group('line editor', () {
    test('inserts text and applies cursor editing keys', () {
      final editor = LineEditor();

      expect(
        editor.apply(const TextInput('coal')).action,
        LineEditAction.changed,
      );
      expect(editor.apply(KeyEvent('left')).action, LineEditAction.changed);
      expect(editor.apply(const TextInput('!')).value, 'coa!l');
      expect(editor.apply(KeyEvent('backspace')).value, 'coal');
      expect(editor.apply(KeyEvent('home')).action, LineEditAction.changed);
      expect(editor.apply(const TextInput('hot ')).value, 'hot coal');
      expect(editor.apply(KeyEvent('end')).action, LineEditAction.changed);
      expect(editor.text, 'hot coal');
    });

    test('supports delete and line clearing shortcuts', () {
      final editor = LineEditor()..apply(const TextInput('abcdef'));

      editor
        ..apply(KeyEvent('left'))
        ..apply(KeyEvent('left'));
      expect(editor.apply(KeyEvent('delete')).value, 'abcdf');
      expect(editor.apply(KeyEvent('u', ctrl: true)).value, 'f');
      expect(editor.apply(KeyEvent('k', ctrl: true)).value, '');
    });

    test('submits, cancels, and reports eof', () {
      final editor = LineEditor();

      editor.apply(const TextInput('coal'));
      final submitted = editor.apply(KeyEvent('enter'));
      expect(submitted.action, LineEditAction.submitted);
      expect(submitted.value, 'coal');
      expect(submitted.isTerminal, isTrue);
      expect(editor.text, isEmpty);
      expect(editor.history.entries, <String>['coal']);

      editor.apply(const TextInput('draft'));
      final canceled = editor.apply(KeyEvent('c', ctrl: true));
      expect(canceled.action, LineEditAction.canceled);
      expect(canceled.value, 'draft');
      expect(
        editor.apply(KeyEvent('d', ctrl: true)).action,
        LineEditAction.eof,
      );
    });

    test('navigates history and restores the draft', () {
      final editor = LineEditor();

      editor
        ..apply(const TextInput('one'))
        ..apply(KeyEvent('enter'))
        ..apply(const TextInput('two'))
        ..apply(KeyEvent('enter'))
        ..apply(const TextInput('dra'));

      expect(editor.apply(KeyEvent('up')).value, 'two');
      expect(editor.apply(KeyEvent('up')).value, 'one');
      expect(editor.apply(KeyEvent('up')).action, LineEditAction.none);
      expect(editor.apply(KeyEvent('down')).value, 'two');
      expect(editor.apply(KeyEvent('down')).value, 'dra');
    });

    test('works with KeyParser output', () {
      final editor = LineEditor();
      final parser = KeyParser();

      for (final input in parser.addString('co\u001b[D!')) {
        editor.apply(input);
      }

      expect(editor.text, 'c!o');
      expect(editor.cursor, 2);
    });
  });
}
