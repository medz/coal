import 'dart:async';
import 'dart:collection';

import 'input_parser.dart';

final class ReadlineInputQueue {
  ReadlineInputQueue(
    Stream<List<int>> input, {
    Duration escapeTimeout = const Duration(milliseconds: 80),
  }) : _input = input {
    _parser = ReadlineInputParser(emit: _add, escapeTimeout: escapeTimeout);
  }

  final Stream<List<int>> _input;
  final Queue<ReadlineInput> _events = Queue<ReadlineInput>();
  final Queue<Completer<ReadlineInput?>> _waiters =
      Queue<Completer<ReadlineInput?>>();
  late final ReadlineInputParser _parser;
  StreamSubscription<List<int>>? _subscription;
  Object? _error;
  StackTrace? _stackTrace;
  bool _done = false;

  Future<ReadlineInput?> next() {
    _listen();

    if (_events.isNotEmpty) {
      return Future<ReadlineInput?>.value(_events.removeFirst());
    }
    if (_error case final error?) {
      return Future<ReadlineInput?>.error(error, _stackTrace);
    }
    if (_done) {
      return Future<ReadlineInput?>.value();
    }

    final completer = Completer<ReadlineInput?>();
    _waiters.add(completer);
    return completer.future;
  }

  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
    _parser.close();
    _done = true;
    while (_waiters.isNotEmpty) {
      _waiters.removeFirst().complete();
    }
  }

  void _listen() {
    _subscription ??= _input.listen(
      _parser.add,
      onError: _fail,
      onDone: _finish,
      cancelOnError: false,
    );
  }

  void _add(ReadlineInput input) {
    if (_waiters.isNotEmpty) {
      _waiters.removeFirst().complete(input);
    } else {
      _events.add(input);
    }
  }

  void _fail(Object error, StackTrace stackTrace) {
    _error = error;
    _stackTrace = stackTrace;
    while (_waiters.isNotEmpty) {
      _waiters.removeFirst().completeError(error, stackTrace);
    }
  }

  void _finish() {
    _parser.close();
    _done = true;
    while (_waiters.isNotEmpty) {
      _waiters.removeFirst().complete();
    }
  }
}
