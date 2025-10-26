import 'package:args/args.dart' as args;
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:coal/args.dart' as coal;

class ArgsBenchmark extends BenchmarkBase {
  const ArgsBenchmark(super.name, this.parse);

  final void Function() parse;

  @override
  void run() => parse();
}

void run(String name, void Function() parse) {
  ArgsBenchmark(name, parse).report();
}

const input = [
  '--a=1',
  '-b',
  '--bool',
  '--no-boop',
  '--multi=foo',
  '--multi=baz',
  '-xyz',
];

void main() {
  run('coal.args', () => coal.Args.parse(input, list: ['multi']));
  run('args', () {
    final parser = args.ArgParser()
      ..addOption("a")
      ..addFlag("b", abbr: 'b')
      ..addFlag('bool')
      ..addFlag('boop')
      ..addMultiOption('multi')
      ..addFlag('x', abbr: 'x')
      ..addFlag('y', abbr: 'y')
      ..addFlag('z', abbr: 'z');
    return () => parser.parse(input);
  }());
}
