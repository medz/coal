typedef CompleteCallback = void Function(String value, String description);
typedef CompleteHandler =
    void Function(CompleteCallback complete, Map<String, Option> options);

class Completion {
  const Completion({required this.value, this.description});

  final String value;
  final String? description;
}

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

class Command {
  Command(this.value, this.description, {this.parent});

  final String value;
  final String description;
  final Command? parent;

  final arguments = <String, Argument>{};
  final options = <String, Option>{};

  Argument argument(
    String name,
    CompleteHandler? handler, {
    bool variadic = false,
  }) {
    return arguments[name] = Argument(this, name, handler, variadic: variadic);
  }

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
      isBool: handler != null,
    );
  }
}
