// Regex used for ansi escape code splitting
// Ref: https://github.com/nodejs/node/blob/main/lib/internal/util/inspect.js#L288
// Matches all ansi escape code sequences in a string
final _ansi = RegExp(
  '[\\u001B\\u009B][[\\]()#;?]*'
  '(?:(?:(?:(?:;[-a-zA-Z\\d\\/\\#&.:=?%@~_]+)*'
  '|[a-zA-Z\\d]+(?:;[-a-zA-Z\\d\\/\\#&.:=?%@~_]*)*)?'
  '(?:\\u0007|\\u001B\\u005C|\\u009C))'
  '|(?:(?:\\d{1,4}(?:;\\d{0,4})*)?'
  '[\\dA-PR-TZcf-nq-uy=><~]))',
);

// Ref: https://github.com/nodejs/node/blob/main/lib/internal/util/inspect.js#L3015
/// Remove all VT control characters. Use to estimate displayed string width.
String stripVTControlCharacters(String text) => text.replaceAll(_ansi, '');
