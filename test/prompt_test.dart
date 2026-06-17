import 'dart:async';
import 'dart:convert';

import 'package:coal/prompt.dart';
import 'package:coal/readline.dart';
import 'package:coal/utils.dart';
import 'package:test/test.dart';

void main() {
  group('prompt', () {
    test('asks for text through readline', () async {
      final harness = _PromptHarness();
      addTearDown(harness.close);

      final answer = harness.prompt.text('Name');
      await harness.pump();
      harness.addText('Ada\r');

      expect(await answer, 'Ada');
      expect(stripVTControlCharacters(harness.outputText), contains('Name: '));
    });

    test('uses default value for an empty answer', () async {
      final harness = _PromptHarness();
      addTearDown(harness.close);

      final answer = harness.prompt.text('Name', defaultValue: 'Ada');
      await harness.pump();
      harness.addText('\r');

      expect(await answer, 'Ada');
      expect(
        stripVTControlCharacters(harness.outputText),
        contains('Name (Ada): '),
      );
    });

    test('returns an empty string without a default value', () async {
      final harness = _PromptHarness();
      addTearDown(harness.close);

      final answer = harness.prompt.text('Name');
      await harness.pump();
      harness.addText('\r');

      expect(await answer, '');
    });

    test('does not render default text for null or empty defaults', () async {
      final nullDefault = _PromptHarness();
      addTearDown(nullDefault.close);

      final first = nullDefault.prompt.text('Name');
      await nullDefault.pump();
      nullDefault.addText('\r');
      await first;

      expect(
        stripVTControlCharacters(nullDefault.outputText),
        contains('Name: '),
      );
      expect(
        stripVTControlCharacters(nullDefault.outputText),
        isNot(contains('()')),
      );

      final emptyDefault = _PromptHarness();
      addTearDown(emptyDefault.close);

      final second = emptyDefault.prompt.text('Name', defaultValue: '');
      await emptyDefault.pump();
      emptyDefault.addText('\r');
      await second;

      expect(
        stripVTControlCharacters(emptyDefault.outputText),
        contains('Name: '),
      );
      expect(
        stripVTControlCharacters(emptyDefault.outputText),
        isNot(contains('()')),
      );
    });

    test('returns null when cancelled', () async {
      final harness = _PromptHarness();
      addTearDown(harness.close);

      final answer = harness.prompt.text('Name');
      await harness.pump();
      harness.addBytes(<int>[0x03]);

      expect(await answer, isNull);
    });

    test('returns null on empty input stream end', () async {
      final harness = _PromptHarness();
      addTearDown(harness.close);

      final answer = harness.prompt.text('Name');
      await harness.pump();
      harness.endInput();

      expect(await answer, isNull);
    });

    test('passes through partial line on input stream end', () async {
      final harness = _PromptHarness();
      addTearDown(harness.close);

      final answer = harness.prompt.text('Name');
      await harness.pump();
      harness.addText('Ada');
      harness.endInput();

      expect(await answer, 'Ada');
    });

    test('rejects concurrent prompts', () async {
      final harness = _PromptHarness();
      addTearDown(harness.close);

      final pending = harness.prompt.text('First');
      await harness.pump();

      expect(harness.prompt.text('Second'), throwsStateError);

      harness.addText('\r');
      await pending;
    });

    test('allows another prompt after cancel and eof', () async {
      final cancel = _PromptHarness();
      addTearDown(cancel.close);

      final cancelled = cancel.prompt.text('Name');
      await cancel.pump();
      cancel.addBytes(<int>[0x03]);
      expect(await cancelled, isNull);

      final afterCancel = cancel.prompt.text('Name');
      await cancel.pump();
      cancel.addText('Ada\r');
      expect(await afterCancel, 'Ada');

      final eof = _PromptHarness();
      addTearDown(eof.close);

      final ended = eof.prompt.text('Name');
      await eof.pump();
      eof.endInput();
      expect(await ended, isNull);

      expect(await eof.prompt.text('Name'), isNull);
    });

    test(
      'allows another prompt call after an input error resets asking',
      () async {
        final harness = _PromptHarness();
        addTearDown(harness.close);

        final failed = harness.prompt.text('Name');
        await harness.pump();
        harness.addError(StateError('boom'));
        await expectLater(
          failed,
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              'boom',
            ),
          ),
        );

        final afterError = harness.prompt.text('Name');
        await expectLater(
          afterError,
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              'boom',
            ),
          ),
        );
      },
    );

    test('close is idempotent and closes pending prompts', () async {
      final harness = _PromptHarness();

      final pending = harness.prompt.text('Name');
      await harness.pump();
      await harness.prompt.close();
      await harness.prompt.close();

      expect(await pending, isNull);
      expect(harness.readline.readLine(), throwsStateError);
      await harness.close();
    });

    test('close before input wait does not subscribe afterward', () async {
      var listenCount = 0;
      final input = StreamController<List<int>>(
        onListen: () {
          listenCount += 1;
        },
      );
      final readline = Readline(input: input.stream, output: StringBuffer());
      final prompt = Prompt(readline: readline);

      final pending = prompt.text('Name');
      await prompt.close();

      expect(await pending, isNull);
      await Future<void>.delayed(Duration.zero);
      expect(listenCount, 0);
      input.close();
    });

    test('reads input emitted synchronously during listen', () async {
      late final StreamController<List<int>> input;
      input = StreamController<List<int>>(
        sync: true,
        onListen: () {
          input.add(utf8.encode('Ada\r'));
        },
      );
      final prompt = Prompt(
        readline: Readline(input: input.stream, output: StringBuffer()),
      );

      final answer = await prompt
          .text('Name')
          .timeout(const Duration(milliseconds: 200));

      expect(answer, 'Ada');
      await prompt.close();
      input.close();
    });

    test('rejects prompts after close', () async {
      final harness = _PromptHarness();
      await harness.close();

      expect(harness.prompt.text('Name'), throwsStateError);
    });
  });
}

final class _PromptHarness {
  _PromptHarness() {
    readline = Readline(input: _controller.stream, output: _output);
    prompt = Prompt(readline: readline);
  }

  final _output = StringBuffer();
  final _controller = StreamController<List<int>>();

  late final Readline readline;
  late final Prompt prompt;
  bool _closed = false;

  String get outputText => _output.toString();

  void addText(String text) {
    addBytes(utf8.encode(text));
  }

  void addBytes(List<int> bytes) {
    _controller.add(bytes);
  }

  void addError(Object error) {
    _controller.addError(error);
  }

  void endInput() {
    _controller.close();
  }

  Future<void> pump() async {
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await prompt.close();
    _controller.close();
  }
}
