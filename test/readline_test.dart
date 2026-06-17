import 'dart:async';
import 'dart:convert';

import 'package:coal/readline.dart';
import 'package:coal/src/readline/line_buffer.dart';
import 'package:coal/src/readline/renderer.dart';
import 'package:coal/utils.dart';
import 'package:test/test.dart';

void main() {
  group('readline', () {
    test('reads a submitted line with a prompt', () async {
      final harness = _ReadlineHarness();
      addTearDown(harness.close);

      final line = harness.readLine(prompt: 'Name: ');
      await harness.pump();
      harness.addText('Ada\r');

      expect(await line, 'Ada');
      expect(
        stripVTControlCharacters(harness.outputText),
        contains('Name: Ada\n'),
      );
    });

    test('handles split escape sequences and split utf8 text', () async {
      final harness = _ReadlineHarness();
      addTearDown(harness.close);

      final line = harness.readLine();
      await harness.pump();
      harness.addText('ab');
      harness.addBytes(<int>[0x1b, 0x5b]);
      harness.addBytes(<int>[0x44]);

      final wide = utf8.encode('中');
      harness.addBytes(<int>[wide[0]]);
      harness.addBytes(<int>[wide[1], wide[2]]);
      harness.addText('\r');

      expect(await line, 'a中b');
    });

    test('does not time out a split CSI sequence', () async {
      final harness = _ReadlineHarness();
      addTearDown(harness.close);

      final line = harness.readLine();
      await harness.pump();
      harness.addText('ab');
      harness.addBytes(<int>[0x1b, 0x5b]);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      harness
        ..addBytes(<int>[0x44])
        ..addText('X\r');

      expect(await line, 'aXb');
    });

    test('does not hang after an incomplete CSI prefix', () async {
      final harness = _ReadlineHarness();
      addTearDown(harness.close);

      final line = harness.readLine();
      await harness.pump();
      harness
        ..addText('x')
        ..addBytes(<int>[0x1b, 0x5b])
        ..addText('\r');

      expect(await line.timeout(const Duration(milliseconds: 200)), 'x');
    });

    test('edits with arrows, backspace, and delete', () async {
      final harness = _ReadlineHarness();
      addTearDown(harness.close);

      final line = harness.readLine();
      await harness.pump();
      harness
        ..addText('abcd')
        ..addText('\x1b[D')
        ..addText('\x1b[D')
        ..addBytes(<int>[0x7f])
        ..addText('\x1b[3~')
        ..addText('\r');

      expect(await line, 'ad');
    });

    test('edits with control shortcuts', () async {
      final harness = _ReadlineHarness();
      addTearDown(harness.close);

      final line = harness.readLine();
      await harness.pump();
      harness
        ..addText('abc')
        ..addText('\x1b[D')
        ..addBytes(<int>[0x15]) // Ctrl-U.
        ..addText('x')
        ..addBytes(<int>[0x0b]) // Ctrl-K.
        ..addText('\r');

      expect(await line, 'x');
    });

    test('navigates history and restores the current draft', () async {
      final harness = _ReadlineHarness(history: <String>['one', 'two']);
      addTearDown(harness.close);

      final first = harness.readLine();
      await harness.pump();
      harness
        ..addText('draft')
        ..addText('\x1b[A')
        ..addText('\x1b[A')
        ..addText('\x1b[B')
        ..addText('\x1b[B')
        ..addText('\r');

      expect(await first, 'draft');

      final second = harness.readLine();
      await harness.pump();
      harness
        ..addText('\x1b[A')
        ..addText('\r');

      expect(await second, 'draft');
    });

    test('editing a history entry exits history navigation', () async {
      final harness = _ReadlineHarness(history: <String>['one', 'two']);
      addTearDown(harness.close);

      final line = harness.readLine();
      await harness.pump();
      harness
        ..addText('\x1b[A')
        ..addBytes(<int>[0x7f])
        ..addText('\x1b[B')
        ..addText('\r');

      expect(await line, 'tw');
    });

    test('returns null for cancel and eof', () async {
      final cancel = _ReadlineHarness();
      addTearDown(cancel.close);

      final cancelled = cancel.readLine();
      await cancel.pump();
      cancel.addBytes(<int>[0x03]); // Ctrl-C.

      expect(await cancelled, isNull);

      final eof = _ReadlineHarness();
      addTearDown(eof.close);

      final ended = eof.readLine();
      await eof.pump();
      eof.addBytes(<int>[0x04]); // Ctrl-D on an empty line.

      expect(await ended, isNull);
    });

    test('ctrl-d deletes forward when the line is not empty', () async {
      final harness = _ReadlineHarness();
      addTearDown(harness.close);

      final line = harness.readLine();
      await harness.pump();
      harness
        ..addText('ab')
        ..addText('\x1b[D')
        ..addBytes(<int>[0x04])
        ..addText('\r');

      expect(await line, 'a');
    });

    test('preserves queued bytes across sequential reads', () async {
      final harness = _ReadlineHarness();
      addTearDown(harness.close);

      final first = harness.readLine();
      await harness.pump();
      harness.addText('first\rsecond\r');

      expect(await first, 'first');
      expect(await harness.readLine(), 'second');
    });

    test('submits buffered text when the input stream ends', () async {
      final harness = _ReadlineHarness();
      addTearDown(harness.close);

      final line = harness.readLine();
      await harness.pump();
      harness.addText('partial');
      await harness.endInput();

      expect(await line, 'partial');
    });

    test('rejects concurrent reads and reads after close', () async {
      final harness = _ReadlineHarness();
      final pending = harness.readLine();
      await harness.pump();

      expect(harness.readline.readLine(), throwsStateError);

      harness.addText('\r');
      await pending;
      await harness.close();

      expect(harness.readline.readLine(), throwsStateError);
    });

    test('renderer clears all rows when redrawing wrapped input', () {
      final output = StringBuffer();
      final renderer = LineRenderer(
        output: output,
        prompt: '> ',
        terminalColumns: 10,
      );
      final buffer = LineBuffer()..insert('123456789012345');

      renderer.render(buffer);
      output.clear();
      buffer.deleteBeforeCursor();
      renderer.render(buffer);

      final redraw = output.toString();
      expect(redraw, contains(cursorUp()));
      expect(redraw, contains(cursorDown()));
      expect(RegExp(RegExp.escape(eraseLine)).allMatches(redraw), hasLength(2));
    });

    test('renderer keeps an exact-width cursor at the row end', () {
      final output = StringBuffer();
      final renderer = LineRenderer(
        output: output,
        prompt: '> ',
        terminalColumns: 10,
      );
      final buffer = LineBuffer()..insert('12345678');

      renderer.render(buffer);

      expect(output.toString(), endsWith(cursorTo(9)));
    });

    test('renderer places a wrapped boundary cursor before following text', () {
      final output = StringBuffer();
      final renderer = LineRenderer(
        output: output,
        prompt: '',
        terminalColumns: 10,
      );
      final buffer = LineBuffer()
        ..insert('12345678901')
        ..moveLeft();

      renderer.render(buffer);

      expect(
        output.toString(),
        endsWith('${cursorUp()}$cursorLeft${cursorDown()}${cursorTo(0)}'),
      );
    });
  });
}

final class _ReadlineHarness {
  _ReadlineHarness({Iterable<String> history = const <String>[]}) {
    readline = Readline(
      input: _controller.stream,
      output: _output,
      history: history,
    );
  }

  final _output = StringBuffer();
  final _controller = StreamController<List<int>>();

  late final Readline readline;

  String get outputText => _output.toString();

  Future<String?> readLine({String prompt = ''}) {
    return readline.readLine(prompt: prompt);
  }

  void addText(String text) {
    addBytes(utf8.encode(text));
  }

  void addBytes(List<int> bytes) {
    _controller.add(bytes);
  }

  Future<void> endInput() {
    return _controller.close();
  }

  Future<void> pump() async {
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> close() async {
    await readline.close();
    await _controller.close();
    _output.clear();
  }
}
