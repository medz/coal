import 'command.dart';
import 'flags.dart';

class CoalTab extends Command {
  CoalTab([String? name, String? description])
    : super(name ?? '', description ?? '');

  final commands = <String, Command>{};
  final completions = <Completion>[];

  ShellCompDirective directive = ShellCompDirective.none;

  Command command(String value, String description) {
    return commands[value] = Command(value, description);
  }
}

extension on CoalTab {
  Option? findOption(Command command, String name) {
    if (command.options[name] case Option option) return option;
    if (command.options[name.withoutDashesLeft] case Option option) {
      return option;
    }

    for (final MapEntry(value: option) in command.options.entries) {
      if (option.alias != null && name == '-${option.alias}') {
        return option;
      }
    }

    return null;
  }

  List<String> stripOptions(Iterable<String> args) {
    final result = <String>[], length = args.length;
    for (int index = 0; index < length;) {
      final arg = args.elementAt(index);
      if (arg.startsWith('-')) {
        index++;
        bool isBool = false;
        if (findOption(this, arg) case final Option option) {
          isBool = option.isBool ?? false;
        } else {
          for (final MapEntry(value: command) in commands.entries) {
            if (findOption(command, arg) case final Option option) {
              isBool = option.isBool ?? false;
              break;
            }
          }
        }

        if (!isBool &&
            index < length &&
            args.elementAt(index).startsWith('-')) {
          index++;
        }
      } else {
        result.add(arg);
        index++;
      }
    }

    return result;
  }
}

extension on String {
  String get withoutDashesLeft {
    if (!startsWith('-')) return this;
    return substring(1).withoutDashesLeft;
  }
}
