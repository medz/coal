enum Action { up, down, left, right, space, enter, cancel }

abstract interface class CoalMessages {
  abstract String cancel;
  abstract String error;
}

abstract interface class CoalSettings {
  Set<Action> get actions;
  Map<String, Action> get aliases;
  CoalMessages get messages;
}

final class _Messages implements CoalMessages {
  @override
  late String cancel = 'Canceled';

  @override
  late String error = 'An error occurred';
}

final class _Setings implements CoalSettings {
  @override
  late final actions = <Action>{...Action.values};

  @override
  late final Map<String, Action> aliases = <String, Action>{
    // Vim
    'k': Action.up,
    'j': Action.down,
    'h': Action.left,
    'l': Action.right,
    '\x03': Action.cancel,

    // opinionated
    'escape': Action.cancel,
  };

  @override
  late final CoalMessages messages = _Messages();
}

final CoalSettings settings = _Setings();

bool isActionKey(Action action, Iterable<String> keys) {
  for (final key in keys) {
    if (settings.aliases[key] == action) return true;
  }
  return false;
}
