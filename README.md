# Coal

A focused utility suite for building polished Dart command-line apps.

Coal is not a CLI framework. It provides small, composable utilities that
improve existing CLI packages and hand-rolled command-line tools.

## Modules

| Entry | Status | Description |
|:----:|:----:|:----|
| [`package:coal/args.dart`](#args-parser) | Supported | Lightweight command-line argument parsing. |
| [`package:coal/utils.dart`](#ansi-utility) | Supported | ANSI escape code, text width, wrapping, and styling utilities. |
| [`package:coal/tab.dart`](#tab) | Supported | Shell completion definitions and script generation. |
| [`package:coal/tab/args.dart`](example/README.md#args-adapter) | Supported | Completion adapter for `package:args` `CommandRunner` apps. |

## CLI

Coal includes a small maintenance CLI:

```bash
dart pub global activate coal
coal doctor
coal complete bash
coal dart-complete bash
```

`coal dart-complete <shell>` prints a completion script for the Dart CLI.
Source it the same way as other shell completion scripts.

## Roadmap

Coal's current plan is to stabilize the supported modules before expanding
into new terminal interaction areas. See [doc/roadmap.md](doc/roadmap.md)
for the release goal, deferred product areas, and readiness gates.

## Installation

Install the package with Dart:

```bash
dart pub add coal
```

## \<TAB\>

<video src="https://github.com/user-attachments/assets/3a298e80-a3d9-4d26-82f5-349eee4650f5" width="640"></video>

### Core

Coal's core \<TAB\> completion implementation allows you to add completion functionality to any Dart command-line app:

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

There is a simple TAB demo → [\<TAB\> example](example/README.md#tab)

> Thanks to [Cobra](https://github.com/spf13/cobra)! for the script and some of the <TAB> implementation references!

The `package:coal/tab/args.dart` adapter can register completion definitions
from a `package:args` `CommandRunner` app. See the
[`args` adapter example](example/README.md#args-adapter).

## Args Parser

Coal provides a lightweight parser for scripts and custom CLI plumbing:

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

Coal provides a series of convenient utilities for generating ANSI escape codes:

- **[Clear](#clear)**: Clear screen utilities.
- **[Cursor](#cursor)**: Cursor manipulation utilities.
- **[Erase](#erase)**: Text erasing utilities.
- **[Scroll](#scroll)**: Screen scrolling utilities.
- **[Text](#text)**: Text styling and manipulation utilities.

### Clear

| Name | Description |
|:----:|:----|
| `clearScreen()` | Clear the terminal screen. |

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
final text = styleText('Hello, World!', [TextStyle.red]);
```

## Development

Before publishing or merging release-oriented changes, run:

```bash
dart format --output=none --set-exit-if-changed .
dart analyze
dart test --exclude-tags=script-runtime
dart test --tags=script-runtime
dart pub publish --dry-run
```

## License

[MIT License](LICENSE)
