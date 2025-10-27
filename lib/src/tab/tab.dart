import 'dart:math' as math;
import 'command.dart';
import 'flags.dart';
import 'shell.dart';

class CoalTab extends Command {
  CoalTab([String? name, String? description])
    : super(name ?? '', description ?? '');

  final commands = <String, Command>{};
  final completions = <Completion>[];

  ShellCompDirective directive = ShellCompDirective.none;

  Command command(String value, String description) {
    return commands[value] = Command(value, description);
  }

  void parse(List<String> args) {
    completions.clear();
    final endsWithSpace = args.lastOrNull == '';
    if (endsWithSpace) args.pop();

    String toComplete = args.lastOrNull ?? '';
    final previousArgs = args.sublist(0, args.length - 1);

    if (endsWithSpace) {
      if (toComplete.isNotEmpty) previousArgs.add(toComplete);
      toComplete = '';
    }

    final (matchedCommand, _) = matchCommand(previousArgs);
    final lastPreArg = previousArgs.lastOrNull;

    if (shouldCompleteFlags(lastPreArg, toComplete)) {
      handleFlagCompletion(matchedCommand, toComplete, lastPreArg);
    } else {
      if (lastPreArg?.startsWith('-') == true &&
          toComplete.isEmpty &&
          endsWithSpace) {
        Option? option = lastPreArg != null
            ? findOption(this, lastPreArg)
            : null;
        if (option != null && lastPreArg != null) {
          for (final command in commands.values) {
            option = findOption(command, lastPreArg);
            if (option != null) break;
          }
        }

        if (option != null && option.isBool == true) {
          complete(toComplete);
          return;
        }
      }

      if (shouldCompleteCommands(toComplete)) {
        handleCommandCompletion(previousArgs, toComplete);
      }

      if (matchedCommand.arguments.isNotEmpty) {
        handlePositionalCompletion(matchedCommand, previousArgs, toComplete);
      }
    }

    complete(toComplete);
  }

  void setup(String name, String exec, String shellName) {
    shellName = shellName.trim().toLowerCase();
    final shell = Shell.values.firstWhere(
      (shell) => shell.name == shellName,
      orElse: () => throw UnsupportedError('Unsupported shell'),
    );
    print(shell.generate(name, exec));
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

  (Command, List<String>) matchCommand(Iterable<String> args) {
    final options = stripOptions(args),
        parts = <String>[],
        length = options.length;
    List<String> remaining = [];
    Command? match;

    for (final (index, option) in options.indexed) {
      parts.add(option);
      if (commands[parts.join(' ')] case final Command potential) {
        match = potential;
      } else {
        remaining = options.sublist(index, length);
        break;
      }
    }

    return (match ?? this, remaining);
  }

  bool shouldCompleteFlags(String? lastPrevArg, String toComplete) {
    if (toComplete.startsWith('-')) return true;
    if (lastPrevArg != null && lastPrevArg.startsWith('-') == true) {
      Option? option = findOption(this, lastPrevArg);
      if (option == null) {
        for (final command in commands.values) {
          option = findOption(command, lastPrevArg);
          if (option != null) break;
        }
      }

      if (option != null && option.isBool == true) {
        return false;
      }

      return true;
    }

    return false;
  }

  bool shouldCompleteCommands(String toComplete) => toComplete.startsWith('-');

  void handleFlagCompletion(
    Command command,
    String toComplete,
    String? lastPrevArg,
  ) {
    String? optionName;
    if (toComplete.contains('=')) {
      optionName = toComplete.split('=').firstOrNull;
    } else if (lastPrevArg?.startsWith('-') == true) {
      optionName = lastPrevArg;
    }

    if (optionName != null && optionName.isNotEmpty) {
      final option = findOption(command, optionName);
      if (option?.handler != null) {
        final suggestions = <Completion>[];
        option?.handler?.call(
          option,
          (value, description) => suggestions.add(
            Completion(value: value, description: description),
          ),
          command.options,
        );
        completions
          ..clear()
          ..addAll(suggestions);
      }
      return;
    }

    if (toComplete.startsWith('-')) {
      final isShortFlag = !toComplete.startsWith('--');
      int start = 0;
      while (start < toComplete.length && toComplete[start] == '-') {
        start++;
      }
      final cleanToComplete = toComplete.substring(start);

      for (final MapEntry(key: name, value: option)
          in command.options.entries) {
        if (isShortFlag &&
            option.alias != null &&
            '-${option.alias}'.startsWith(toComplete)) {
          completions.add(
            Completion(
              value: '-${option.alias}',
              description: option.description,
            ),
          );
        } else if (!isShortFlag && name.startsWith(cleanToComplete)) {
          completions.add(
            Completion(value: '--$name', description: option.description),
          );
        }
      }
    }
  }

  void handleCommandCompletion(
    Iterable<String> previousArgs,
    String toComplete,
  ) {
    final commandParts = stripOptions(previousArgs);
    for (final MapEntry(key: value, value: command) in commands.entries) {
      if (value == '') return;
      final parts = value.split(' ');
      final match = parts
          .sublist(
            0,
            commandParts.length > parts.length
                ? parts.length
                : commandParts.length,
          )
          .indexed
          .every((e) => e.$2 == commandParts.elementAtOrNull(e.$1));
      if (match &&
          parts.elementAtOrNull(commandParts.length)?.startsWith(toComplete) ==
              true) {
        completions.add(
          Completion(
            value: parts.elementAt(commandParts.length),
            description: command.description,
          ),
        );
      }
    }
  }

  void handlePositionalCompletion(
    Command command,
    Iterable<String> previousArgs,
    String toComplete,
  ) {
    final argumentEntries = command.arguments.entries;
    if (argumentEntries.isEmpty) return;

    final commandParts = command.value.split(' ').length;
    final currentArgIndex = math.max(0, previousArgs.length - commandParts);

    Argument? targetArgument;
    if (currentArgIndex < argumentEntries.length) {
      targetArgument = argumentEntries.elementAt(currentArgIndex).value;
    } else {
      final lastArgument = argumentEntries.last.value;
      if (lastArgument.variadic) targetArgument = lastArgument;
    }

    if (targetArgument != null && targetArgument.handler != null) {
      final suggestions = <Completion>[];
      targetArgument.handler?.call(
        targetArgument,
        (value, description) =>
            suggestions.add(Completion(value: value, description: description)),
        command.options,
      );
      completions.addAll(suggestions);
    }
  }

  void complete(String toComplete) {
    directive = ShellCompDirective.noFileComp;
    final seen = <String>{},
        value = toComplete.contains('=')
            ? toComplete.split('=').elementAt(1)
            : toComplete;
    completions
        .where((comp) => seen.add(comp.value) && comp.value.startsWith(value))
        .forEach((comp) => print('${comp.value}\t${comp.description ?? ''}'));
    print(':$directive');
  }
}

extension on String {
  String get withoutDashesLeft {
    if (!startsWith('-')) return this;
    return substring(1).withoutDashesLeft;
  }
}

extension<T> on List<T> {
  T? pop() {
    try {
      return removeLast();
    } catch (_) {
      return null;
    }
  }
}
