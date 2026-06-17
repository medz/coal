import 'dart:async';
import 'dart:convert';

import 'package:coal/prompt.dart';
import 'package:coal/prompt_utils.dart';
import 'package:coal/readline.dart';
import 'package:coal/utils.dart';
import 'package:test/test.dart';

void main() {
  group('prompt utils', () {
    test('confirm parses yes and no answers', () async {
      await _expectConfirmAnswer(' y ', isTrue);
      await _expectConfirmAnswer('yes', isTrue);
      await _expectConfirmAnswer('n', isFalse);
      await _expectConfirmAnswer('no', isFalse);
    });

    test('confirm uses defaults for empty answers', () async {
      final yes = _PromptHarness();
      addTearDown(yes.close);

      final confirmed = yes.prompt.confirm('Continue', defaultValue: true);
      await yes.pump();
      yes.addText('\r');

      expect(await confirmed, isTrue);
      expect(
        stripVTControlCharacters(yes.outputText),
        contains('Continue (Y/n): '),
      );

      final no = _PromptHarness();
      addTearDown(no.close);

      final rejected = no.prompt.confirm('Continue', defaultValue: false);
      await no.pump();
      no.addText('\r');

      expect(await rejected, isFalse);
      expect(
        stripVTControlCharacters(no.outputText),
        contains('Continue (y/N): '),
      );
    });

    test(
      'confirm retries empty and invalid answers without a default',
      () async {
        final harness = _PromptHarness();
        addTearDown(harness.close);

        final answer = harness.prompt.confirm('Continue');
        await harness.pump();
        harness.addText('\rmaybe\ry\r');

        expect(await answer, isTrue);
        final output = stripVTControlCharacters(harness.outputText);
        expect(output, contains('Continue: '));
        expect(output, contains('Please answer yes or no: '));
      },
    );

    test('confirm keeps defaults after invalid answers', () async {
      final harness = _PromptHarness();
      addTearDown(harness.close);

      final answer = harness.prompt.confirm('Continue', defaultValue: false);
      await harness.pump();
      harness.addText('maybe\r\r');

      expect(await answer, isFalse);
      final output = stripVTControlCharacters(harness.outputText);
      expect(output, contains('Continue (y/N): '));
      expect(output, contains('Please answer yes or no (y/N): '));
    });

    test('confirm returns null when cancelled or input ends', () async {
      final cancel = _PromptHarness();
      addTearDown(cancel.close);

      final cancelled = cancel.prompt.confirm('Continue');
      await cancel.pump();
      cancel.addBytes(<int>[0x03]);

      expect(await cancelled, isNull);

      final eof = _PromptHarness();
      addTearDown(eof.close);

      final ended = eof.prompt.confirm('Continue');
      await eof.pump();
      eof.endInput();

      expect(await ended, isNull);
    });

    test('confirm does not swallow prompt errors', () async {
      final harness = _PromptHarness();
      addTearDown(harness.close);

      final answer = harness.prompt.confirm('Continue');
      await harness.pump();
      harness.addError(StateError('boom'));

      await expectLater(
        answer,
        throwsA(
          isA<StateError>().having((error) => error.message, 'message', 'boom'),
        ),
      );
    });
  });
}

Future<void> _expectConfirmAnswer(String input, Matcher matcher) async {
  final harness = _PromptHarness();
  addTearDown(harness.close);

  final answer = harness.prompt.confirm('Continue');
  await harness.pump();
  harness.addText('$input\r');
  expect(await answer, matcher);
}

final class _PromptHarness {
  _PromptHarness() {
    final readline = Readline(input: _controller.stream, output: _output);
    prompt = Prompt(readline: readline);
  }

  final _output = StringBuffer();
  final _controller = StreamController<List<int>>();

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
