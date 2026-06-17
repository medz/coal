final _supportedShellCommandName = RegExp(r'^[A-Za-z0-9_][A-Za-z0-9_.:-]*$');

const shellCommandNameRequirement =
    'letters, numbers, dot, underscore, hyphen, or colon, and starting '
    'with a letter, number, or underscore';

void validateShellCommandName(
  String name, {
  required String context,
  String suffix = '.',
}) {
  if (_supportedShellCommandName.hasMatch(name)) return;

  throw UnsupportedError(
    '$context containing only $shellCommandNameRequirement$suffix',
  );
}
