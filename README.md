# Coal

Composable utilities for Dart command-line apps.

Coal is not a CLI framework. It provides focused helpers that can be used with
plain Dart CLIs or existing command packages.

## Modules

| Entry | Description |
|:----|:----|
| [`package:coal/args.dart`](#args-parser) | Lightweight command-line argument parsing. |
| [`package:coal/utils.dart`](#ansi-utility) | ANSI escape-code and terminal text helpers. |
| [`package:coal/tab.dart`](#tab) | Shell completion definitions and script generation. |
| [`package:coal/tab/args.dart`](example/README.md#args-adapter) | Adapter for `package:args` `CommandRunner` apps. |

## Installation

```bash
dart pub add coal
```

## \<TAB\>

<video src="https://github.com/user-attachments/assets/3a298e80-a3d9-4d26-82f5-349eee4650f5" width="640"></video>

### Core

Define a completion tree and print shell scripts from your CLI:

```dart
import 'package:coal/tab.dart';

final tab = Tab();
final complete = tab.command('complete', '<TAB> autocompletion');

complete.argument('shell', (complete, _) {
  complete('bash', 'Setup bash shell completion');
  complete('zsh', 'Setup zsh shell completion');
  complete('fish', 'Setup fish shell completion');
  complete('powershell', 'Setup powershell shell completion');
});
```

See the runnable [\<TAB\> example](example/README.md#tab).

Completion scripts are synced from upstream
[Cobra](https://github.com/spf13/cobra) behavior and covered by script
contract tests.

## Args Parser

Parse raw command-line tokens into a JSON-friendly argument tree:

```dart
import 'package:coal/args.dart';

const input = [
  '--a=1',
  '-b',
  '--bool',
  '--no-boop',
  '--multi=foo',
  '--multi=baz',
  '-xyz',
];
final args = Args.parse(input, list: ['multi']);

print(args.toJson());
```
```json
{
  "a": 1,
  "b": true,
  "bool": true,
  "boop": false,
  "multi": ["foo", "baz"],
  "x": true,
  "y": true,
  "z": true
}
```

## ANSI Utility

Generate ANSI escape codes and measure or wrap terminal text:

- **[Clear](#clear)**: Clear screen utilities.
- **[Cursor](#cursor)**: Cursor manipulation utilities.
- **[Erase](#erase)**: Text erasing utilities.
- **[Scroll](#scroll)**: Screen scrolling utilities.
- **[Text](#text)**: Text styling and manipulation utilities.

### Clear

| Name | Description |
|:----:|:----|
| `clearScreen` | Clear the terminal screen. |

### Cursor

| Name | Description |
|:----:|:----|
| `cursorUp()` | Move the cursor up by `count` lines. |
| `cursorDown()` | Move the cursor down by `count` lines. |
| `cursorForward()` | Move the cursor forward by `count` columns. |
| `cursorBackward()` | Move the cursor backward by `count` columns. |
| `cursorNextLine()` | Move the cursor to the next line by `count` lines. |
| `cursorPrevLine()` | Move the cursor to the previous line by `count` lines. |
| `cursorTo()` | Move the cursor to the specified position. |
| `cursorMove()` | Move the cursor by `x` columns and `y` lines. |
| `cursorShow` | Show the cursor. |
| `cursorHide` | Hide the cursor. |
| `cursorSave` | Save the cursor position. |
| `cursorRestore` | Restore the cursor position. |
| `cursorLeft` | Move the cursor to the first column. |

### Erase

| Name | Description |
|:----:|:----|
| `eraseScreen` | Erase the entire screen. |
| `eraseLine` | Erase the current line. |
| `eraseLineStart` | Erase from the current cursor position to the beginning of the line. |
| `eraseLineEnd` | Erase from the current cursor position to the end of the line. |
| `eraseUp()` | Erase `count` lines above the current cursor position. |
| `eraseDown()` | Erase `count` lines below the current cursor position. |
| `eraseLines()` | Erase `count` lines above and below the current cursor position. |

### Scroll

| Name | Description |
|:----:|:----|
| `scrollUp()` | Scroll the screen up by `count` lines. |
| `scrollDown()` | Scroll the screen down by `count` lines. |
| `scrollLeft()` | Scroll the screen left by `count` columns. |
| `scrollRight()` | Scroll the screen right by `count` columns. |

### Text

- `stripVTControlCharacters()`: Remove all VT control characters. Use to estimate displayed string width.
- `getTextTruncatedWidth()`: Get the width of a string when truncated to fit within a given width.
- `getTextWidth()`: Get the width of a string.
- `wrapAnsi()`: Wrap a string to fit within a given width.
- `styleText()`: Generate a string with ANSI escape codes for styling.

#### Style Text

```dart
final text = styleText('Hello, World!', [TextStyle.red, TextStyle.bold]);
```

## License

[MIT License](LICENSE)
