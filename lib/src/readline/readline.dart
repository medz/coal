import 'dart:async';
import 'dart:io' as io;

import '../keypass/key_event.dart';
import 'history.dart';
import 'input_parser.dart';
import 'input_queue.dart';
import 'line_buffer.dart';
import 'renderer.dart';
import 'terminal_mode.dart';

/// Interactive line input with editing-friendly terminal behavior.
final class Readline {
  /// Creates a readline instance from injected input and output streams.
  Readline({
    required Stream<List<int>> input,
    required StringSink output,
    int historyLimit = 100,
    Iterable<String> history = const <String>[],
  }) : this._(
         input: input,
         output: output,
         historyLimit: historyLimit,
         history: history,
         terminalColumns: 80,
       );

  Readline._({
    required Stream<List<int>> input,
    required StringSink output,
    required int historyLimit,
    required Iterable<String> history,
    required int terminalColumns,
    TerminalMode? terminalMode,
  }) : _input = ReadlineInputQueue(input),
       _output = output,
       _terminalMode = terminalMode,
       _terminalColumns = terminalColumns,
       _history = LineHistory(limit: historyLimit, entries: history);

  /// Creates a readline instance backed by process stdio.
  factory Readline.stdio({
    io.Stdin? input,
    StringSink? output,
    int historyLimit = 100,
    Iterable<String> history = const <String>[],
  }) {
    final stdin = input ?? io.stdin;
    final stdout = output ?? io.stdout;
    return Readline._(
      input: stdin,
      output: stdout,
      historyLimit: historyLimit,
      history: history,
      terminalColumns: _outputTerminalColumns(stdout),
      terminalMode: StdinTerminalMode(stdin),
    );
  }

  final ReadlineInputQueue _input;
  final StringSink _output;
  final TerminalMode? _terminalMode;
  final int _terminalColumns;
  final LineHistory _history;
  bool _reading = false;
  bool _closed = false;

  /// Reads one edited line.
  ///
  /// Returns `null` when input ends, Ctrl-D is pressed on an empty line, or the
  /// line is cancelled with Ctrl-C.
  Future<String?> readLine({String prompt = ''}) async {
    if (_closed) {
      throw StateError('Readline is closed.');
    }
    if (_reading) {
      throw StateError('Readline is already reading.');
    }

    _reading = true;
    final buffer = LineBuffer();
    final renderer = LineRenderer(
      output: _output,
      prompt: prompt,
      terminalColumns: _terminalColumns,
    );

    try {
      _terminalMode?.enterRawMode();
      renderer.render(buffer);
      await _flushOutput();

      while (true) {
        final input = await _input.next();
        if (input == null) {
          renderer.finishLine();
          if (buffer.isEmpty) return null;
          final line = buffer.text;
          _history.add(line);
          return line;
        }

        switch (input) {
          case ReadlineTextInput(:final text):
            buffer.insert(text);
            _history.resetNavigation();
            renderer.render(buffer);
          case ReadlineKeyInput(:final event):
            final action = _handleKey(event, buffer, renderer);
            switch (action) {
              case _ReadlineContinue():
                break;
              case _ReadlineSubmit(:final line):
                _history.add(line);
                return line;
              case _ReadlineCancel():
                return null;
            }
        }

        await _flushOutput();
      }
    } finally {
      _terminalMode?.restore();
      await _flushOutput();
      _reading = false;
    }
  }

  /// Stops reading from the input stream.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _input.close();
    _terminalMode?.restore();
    await _flushOutput();
  }

  _ReadlineAction _handleKey(
    KeyEvent event,
    LineBuffer buffer,
    LineRenderer renderer,
  ) {
    switch (event.binding) {
      case 'enter':
        renderer.finishLine();
        return _ReadlineSubmit(buffer.text);
      case 'ctrl+c':
        renderer.finishLine();
        return const _ReadlineCancel();
      case 'ctrl+d':
        if (buffer.isEmpty) {
          renderer.finishLine();
          return const _ReadlineCancel();
        }
        if (buffer.deleteAtCursor()) {
          _history.resetNavigation();
          renderer.render(buffer);
        }
      case 'backspace' || 'ctrl+h':
        if (buffer.deleteBeforeCursor()) {
          _history.resetNavigation();
          renderer.render(buffer);
        }
      case 'delete':
        if (buffer.deleteAtCursor()) {
          _history.resetNavigation();
          renderer.render(buffer);
        }
      case 'left' || 'ctrl+b':
        if (buffer.moveLeft()) renderer.render(buffer);
      case 'right' || 'ctrl+f':
        if (buffer.moveRight()) renderer.render(buffer);
      case 'home' || 'ctrl+a':
        if (buffer.moveHome()) renderer.render(buffer);
      case 'end' || 'ctrl+e':
        if (buffer.moveEnd()) renderer.render(buffer);
      case 'ctrl+u':
        if (buffer.clearBeforeCursor()) {
          _history.resetNavigation();
          renderer.render(buffer);
        }
      case 'ctrl+k':
        if (buffer.clearAfterCursor()) {
          _history.resetNavigation();
          renderer.render(buffer);
        }
      case 'up':
        if (_history.previous(buffer.text) case final line?) {
          buffer.replace(line);
          renderer.render(buffer);
        }
      case 'down':
        if (_history.next() case final line?) {
          buffer.replace(line);
          renderer.render(buffer);
        }
      case 'tab':
        buffer.insert('\t');
        _history.resetNavigation();
        renderer.render(buffer);
    }

    return const _ReadlineContinue();
  }

  Future<void> _flushOutput() async {
    final output = _output;
    if (output is io.IOSink) {
      await output.flush();
    }
  }
}

sealed class _ReadlineAction {
  const _ReadlineAction();
}

final class _ReadlineContinue extends _ReadlineAction {
  const _ReadlineContinue();
}

final class _ReadlineSubmit extends _ReadlineAction {
  const _ReadlineSubmit(this.line);

  final String line;
}

final class _ReadlineCancel extends _ReadlineAction {
  const _ReadlineCancel();
}

int _outputTerminalColumns(StringSink output) {
  if (output is io.Stdout && output.hasTerminal) {
    return output.terminalColumns;
  }
  return 80;
}
