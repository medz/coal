import 'package:args/args.dart' as argsPkg;
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
  final args = coal.Args.parse(input, list: ['multi']);
  print(args);
  print(args.toJson());

  run('coal.args', () => coal.Args.parse(input, list: ['multi']));
  run('args', () {
    final parser = argsPkg.ArgParser()
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
