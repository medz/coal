import 'package:coal/args.dart';
import 'package:test/test.dart';

void main() {
  group("flags", () {
    test("a b c", () {
      const input = ["a", "b", "c"];
      final args = Args.parse(input);
      expect(args.rest, input);
    });

    test("-a -b -c", () {
      const input = ["-a", "-b", "-c"];
      const output = {"a": true, "b": true, "c": true};
      final args = Args.parse(input);
      expect(args.toJson(), output);
    });

    test("-a 1 -b 2 -c 3 -d -e", () {
      const input = ["-a", "1", "-b", "2", "-c", "3", "-d", "-e"];
      const output = {"a": 1, "b": 2, "c": 3, "d": true, "e": true};
      final args = Args.parse(input);
      expect(args.toJson(), output);
    });

    test("-a=1 -b 2 -c=3 -d -e", () {
      const input = ["-a", "1", "-b", "2", "-c", "3", "-d", "-e"];
      const output = {"a": 1, "b": 2, "c": 3, "d": true, "e": true};
      final args = Args.parse(input);
      expect(args.toJson(), output);
    });

    test('-a aaa bbb -b ccc ddd -c 3 -d -e', () {
      const input = [
        "-a",
        "aaa",
        "bbb",
        "-b",
        "ccc",
        "ddd",
        "-c",
        "3",
        "-d",
        "-e",
      ];
      const output = {"a": "aaa", "b": "ccc", "c": 3, "d": true, "e": true};
      const rest = ["bbb", "ddd"];
      final args = Args.parse(input);
      expect(args.toJson(), output);
      expect(args.rest, rest);
    });

    test(r'-a "aaa bbb" -b "ccc ddd" -c 3 -d -e', () {
      const input = [
        r'-a',
        r'"aaa bbb"',
        r'-b',
        r'"ccc ddd"',
        r'-c',
        r'3',
        r'-d',
        r'-e',
      ];
      const output = {
        "a": "aaa bbb",
        "b": "ccc ddd",
        "c": 3,
        "d": true,
        "e": true,
      };
      final args = Args.parse(input);
      expect(args.toJson(), output);
    });

    test("comprehensive", () {
      const input = [
        "--name=meowmers",
        "bare",
        "-cats",
        "woo",
        "-h",
        "awesome",
        "--multi=quux",
        "--key",
        "value",
        "-b",
        "--bool",
        "--no-meep",
        "--multi=baz",
        "-f=abc=def",
      ];
      const output = {
        "c": true,
        "a": true,
        "t": true,
        "f": "abc=def",
        "s": "woo",
        "h": "awesome",
        "b": true,
        "bool": true,
        "key": "value",
        "multi": "baz",
        "meep": false,
        "name": "meowmers",
      };
      const rest = ["bare"];
      final args = Args.parse(input);
      expect(args.toJson(), output);
      expect(args.rest, rest);
    });

    test("collects repeated list values when the option is typed as list", () {
      const input = ["--multi=foo", "--multi=baz"];
      const output = {
        "multi": ["foo", "baz"],
      };
      final args = Args.parse(input, list: ["multi"]);

      expect(args.toJson(), output);
    });
  });

  group("dotted", () {
    test("-a.a1 1 -b.b1 2 -c.c1 3 -d -e", () {
      const input = ["-a.a1", "1", "-b.b1", "2", "-c.c1", "3", "-d", "-e"];
      const output = {"a": ".a1", "b": ".b1", "c": ".c1", "d": true, "e": true};
      const rest = [1, 2, 3];
      final args = Args.parse(input);
      expect(args.toJson(), output);
      expect(args.args, rest);
    });

    test("--a.a1 1 --b.b1 2 --c.c1 3 -d -e", () {
      const input = ["--a.a1", "1", "--b.b1", "2", "--c.c1", "3", "-d", "-e"];
      const output = {
        "a": {"a1": 1},
        "b": {"b1": 2},
        "c": {"c1": 3},
        "d": true,
        "e": true,
      };
      final args = Args.parse(input);
      expect(args.toJson(), output);
    });

    test("--a.a1.a2 1 --b.b1.b2 2 --c.c1.c2 3 -d -e", () {
      const input = [
        "--a.a1.a2",
        "1",
        "--b.b1.b2",
        "2",
        "--c.c1.c2",
        "3",
        "-d",
        "-e",
      ];
      const output = {
        "a": {
          "a1": {"a2": 1},
        },
        "b": {
          "b1": {"b2": 2},
        },
        "c": {
          "c1": {"c2": 3},
        },
        "d": true,
        "e": true,
      };
      final args = Args.parse(input);
      expect(args.toJson(), output);
    });

    test("preserves sibling values under the same dotted parent", () {
      const input = ["--a.b=1", "--a.c=2", "--a.d.e=3"];
      const output = {
        "a": {
          "b": 1,
          "c": 2,
          "d": {"e": 3},
        },
      };
      final args = Args.parse(input);
      expect(args.toJson(), output);
    });

    test("appends repeated dotted list values without replacing siblings", () {
      const input = ["--a.b=1", "--a.list=2", "--a.list=3"];
      const output = {
        "a": {
          "b": 1,
          "list": [2, 3],
        },
      };
      final args = Args.parse(input, list: ["a.list"]);
      expect(args.toJson(), output);
    });
  });

  group("negated", () {
    test("supports unknown", () {
      const input = ["--no-bundle", "--watch"];
      const output = {"bundle": false, "watch": true};
      final args = Args.parse(input);
      expect(args.toJson(), output);
    });

    test("ignores strings", () {
      const input = ["--no-bundle", "--watch"];
      const output = {'no-bundle': '', "watch": true};
      final args = Args.parse(input, string: ["no-bundle"]);
      expect(args.toJson(), output);
    });

    test("ignores arrays", () {
      const input = ["--no-bundle", '1', "--watch"];
      const output = {
        'no-bundle': [1],
        "watch": true,
      };
      final args = Args.parse(input, list: ["no-bundle"]);
      expect(args.toJson(), output);
    });
  });

  group("aliases", () {
    test("works", () {
      const input = ["-h"];
      const aliases = {'h': 'help'};
      const output = {"help": true};
      final args = Args.parse(input, aliases: aliases);
      expect(args.toJson(), output);
    });

    test("applies list type hints after alias resolution", () {
      const input = ["-m=one", "-m=two"];
      const output = {
        "multi": ["one", "two"],
      };
      final args = Args.parse(input, aliases: {'m': 'multi'}, list: ['multi']);

      expect(args.toJson(), output);
    });

    test("applies string type hints after alias resolution", () {
      final args = Args.parse(
        const ["-s"],
        aliases: {'s': 'name'},
        string: ['name'],
      );

      expect(args.toJson(), {"name": ""});
    });

    test("applies aliases to short dotted values", () {
      final args = Args.parse(const ["-a.foo"], aliases: {'a': 'alpha'});

      expect(args.toJson(), {"alpha": ".foo"});
    });

    test("applies type hints to short dotted aliases", () {
      final args = Args.parse(
        const ["-a.foo"],
        aliases: {'a': 'alpha'},
        list: ['alpha'],
      );

      expect(args.toJson(), {
        "alpha": [".foo"],
      });
    });

    test("keeps alias targets starting with no- as normal options", () {
      final args = Args.parse(const ["-n"], aliases: {'n': 'no-cache'});

      expect(args.toJson(), {"no-cache": true});
    });

    test("ignores strings", () {
      const input = ["--no-bundle", "--watch"];
      const output = {'no-bundle': '', "watch": true};
      final args = Args.parse(input, string: ['no-bundle']);
      expect(args.toJson(), output);
    });

    test("ignores arrays", () {
      const input = ["--no-bundle", '1', "--watch"];
      const output = {
        'no-bundle': [1],
        "watch": true,
      };
      final args = Args.parse(input, list: ['no-bundle']);
      expect(args.toJson(), output);
    });
  });

  group("special cases", () {
    test("just a hyphen", () {
      const input = ["-"];
      final args = Args.parse(input);

      expect(args.rest, input);
    });

    test("string after boolean should be treated as postestional", () {
      const rest = ["http://github.com/medz/coal"];
      const input = ["--get", ...rest];
      const output = {"get": true};
      final args = Args.parse(input, bool: ['get']);

      expect(args.toJson(), output);
      expect(args.rest, rest);
      expect(args.args, rest);
    });

    test("empty input preserves defaults without double wrapping", () {
      const defaults = {
        "port": 3000,
        "nested": {"enabled": true},
      };
      final args = Args.parse(const [], defaults: defaults);

      expect(args.toJson(), defaults);
    });

    test("dotted values extend nested defaults", () {
      const defaults = {
        "server": {"host": "localhost"},
      };
      const output = {
        "server": {"host": "localhost", "port": 3000},
      };
      final args = Args.parse(const ["--server.port=3000"], defaults: defaults);

      expect(args.toJson(), output);
    });

    test("single dot value remains a string", () {
      final args = Args.parse(const ["--path=."]);

      expect(args.toJson(), {"path": "."});
    });

    test("numeric-looking invalid values remain strings", () {
      final args = Args.parse(const ["--a=1a", "--b=.5a", "--c=1.2.3"]);

      expect(args.toJson(), {"a": "1a", "b": ".5a", "c": "1.2.3"});
    });

    test("bare list option is an empty list", () {
      final args = Args.parse(const ["--items"], list: ["items"]);

      expect(args.toJson(), {"items": []});
    });
  });

  group("boolean flags", () {
    test("should handle long-form boolean flags correctly", () {
      const input = ["--add"];
      const output = {'add': true};
      final args = Args.parse(input, bool: ['add']);

      expect(args.toJson(), output);
    });

    test("should handle alias boolean flags correctly", () {
      const input = ["-a"];
      const output = {'add': true};
      final args = Args.parse(input, aliases: {'a': "add"}, bool: ['add']);

      expect(args.toJson(), output);
    });
  });
}
