import '../shell_command_name.dart' as shell_names;

void validateShellCommandName(String name) {
  shell_names.validateShellCommandName(
    name,
    context: 'Shell completion scripts require a command name',
  );
}

String nameForVar(String name) {
  final buffer = StringBuffer();
  for (final unit in name.codeUnits) {
    final isDigit = unit >= 0x30 && unit <= 0x39;
    final isUpper = unit >= 0x41 && unit <= 0x5a;
    final isLower = unit >= 0x61 && unit <= 0x7a;

    if (isDigit || isUpper || isLower) {
      buffer.writeCharCode(unit);
    } else if (unit == 0x5f) {
      buffer.write('__');
    } else {
      buffer
        ..write('_x')
        ..write(unit.toRadixString(16).padLeft(2, '0'))
        ..write('_');
    }
  }

  return buffer.toString();
}

List<String> splitCommandPrefix(
  String command, {
  bool backslashEscapes = true,
  bool powershellSingleQuotes = false,
}) {
  final words = <String>[];
  final buffer = StringBuffer();
  String? quote;
  var escaping = false;
  var hasWord = false;

  void finishWord() {
    if (!hasWord) return;
    words.add(buffer.toString());
    buffer.clear();
    hasWord = false;
  }

  for (var i = 0; i < command.length; i++) {
    final char = command[i];

    if (escaping) {
      buffer.write(char);
      escaping = false;
      hasWord = true;
      continue;
    }

    if (quote == null) {
      if (char.trim().isEmpty) {
        finishWord();
      } else if (char == "'" || char == '"') {
        quote = char;
        hasWord = true;
      } else if (backslashEscapes && char == '\\') {
        escaping = true;
        hasWord = true;
      } else {
        buffer.write(char);
        hasWord = true;
      }
      continue;
    }

    if (quote == "'") {
      if (char == "'") {
        if (powershellSingleQuotes &&
            i + 1 < command.length &&
            command[i + 1] == "'") {
          buffer.write("'");
          i++;
        } else {
          quote = null;
        }
      } else {
        buffer.write(char);
      }
      continue;
    }

    if (char == '"') {
      quote = null;
    } else if (backslashEscapes && char == '\\') {
      if (i + 1 < command.length) {
        final next = command[i + 1];
        if (next == r'\' || next == r'$' || next == '`' || next == '"') {
          buffer.write(next);
          i++;
        } else {
          buffer.write(char);
        }
      } else {
        buffer.write(char);
      }
    } else {
      buffer.write(char);
    }
  }

  if (escaping) {
    throw ArgumentError.value(
      command,
      'command',
      'Shell completion command cannot end with an escape character',
    );
  }
  if (quote != null) {
    throw ArgumentError.value(
      command,
      'command',
      'Shell completion command has an unterminated quoted string',
    );
  }

  finishWord();
  if (words.isEmpty) {
    throw ArgumentError.value(
      command,
      'command',
      'Shell completion command cannot be empty',
    );
  }
  return words;
}

String shellSingleQuote(String value) {
  return "'${value.replaceAll("'", r"'\''")}'";
}

String shellWords(String command) {
  return splitCommandPrefix(command).map(shellSingleQuote).join(' ');
}

String fishSingleQuote(String value) {
  return "'${value.replaceAll('\\', r'\\').replaceAll("'", r"\'")}'";
}

String fishWords(String command) {
  return splitCommandPrefix(command).map(fishSingleQuote).join(' ');
}

String powershellSingleQuote(String value) {
  return "'${value.replaceAll("'", "''")}'";
}

String powershellWords(String command) {
  return splitCommandPrefix(
    command,
    backslashEscapes: false,
    powershellSingleQuotes: true,
  ).map(powershellSingleQuote).join(', ');
}
