extension type const ShellCompleteDirective._(int _) {
  static const none = ShellCompleteDirective._(0);
  static const error = ShellCompleteDirective._(1 << 0);
  static const noSpace = ShellCompleteDirective._(1 << 1);
  static const noFileCompletion = ShellCompleteDirective._(1 << 2);
  static const filterFileExtension = ShellCompleteDirective._(1 << 3);
  static const filterDirectory = ShellCompleteDirective._(1 << 4);
  static const keepOrder = ShellCompleteDirective._(1 << 5);
  static const maxValue = ShellCompleteDirective._(1 << 6);
}

typedef CompleteCallback = void Function(String value, String description);
typedef CompleteHandler<T> =
    void Function(T param, CompleteCallback complete, Map<String, Option>);

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
  final CompleteHandler<Argument>? handler;
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
  final CompleteHandler<Option>? handler;
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
    CompleteHandler<Argument>? handler, {
    bool variadic = false,
  }) {
    return arguments[name] = Argument(this, name, handler, variadic: variadic);
  }

  Option option(
    String value,
    String description,
    CompleteHandler<Option>? handler, {
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
