/// Adds a single completion entry.
typedef Complete = void Function(String value, String description);
/// Provides completion entries for an argument or option.
typedef CompleteHandler =
    void Function(Complete complete, Map<String, Option> options);

/// Represents a completion entry returned to the shell.
class Completion {
  const Completion({required this.value, this.description});

  final String value;
  final String? description;
}

/// Defines a positional argument on a command.
class Argument {
  const Argument(
    this.command,
    this.name,
    this.handler, {
    this.variadic = false,
  });

  final String name;
  final bool variadic;
  final Command command;
  final CompleteHandler? handler;
}

/// Defines an option on a command.
class Option {
  const Option(
    this.command,
    this.value,
    this.description,
    this.handler, {
    this.alias,
    this.isBool,
  });

  final Command command;
  final String value;
  final String description;
  final String? alias;
  final bool? isBool;
  final CompleteHandler? handler;
}

/// Command definition used to build completion trees.
class Command {
  Command(this.value, this.description, {this.parent});

  final String value;
  final String description;
  final Command? parent;

  final arguments = <String, Argument>{};
  final options = <String, Option>{};

  /// Registers a positional argument and returns the created definition.
  Argument argument(
    String name,
    CompleteHandler? handler, {
    bool variadic = false,
  }) {
    return arguments[name] = Argument(this, name, handler, variadic: variadic);
  }

  /// Registers an option and returns the created definition.
  Option option(
    String value,
    String description,
    CompleteHandler? handler, {
    String? alias,
  }) {
    return options[value] = Option(
      this,
      value,
      description,
      handler,
      alias: alias,
      isBool: handler == null,
    );
  }
}
