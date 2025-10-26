# Coal

A suite for easily building beautiful command-line apps.

> [!WARNING]
> **The Coal is still in development and may not be fully functional.**
>
> Coal is not a CLI framework! It's intended to provide a convenient and easy-to-use command-line tool for existing CLI frameworks and developers.
>
> **Coal also doesn't plan to add command functionality. Its purpose is to enhance existing CLI packages.**

## Modules

| Entry | Description |
|:----:|:----|
| [`package:coal/args.dart`](#args-parser) | Provides command-line argument parsing functionality. |
| [`package:coal/utils.dart`](#ansi-utility) | Provides utility functions for ANSI escape codes. |

## Roadmap

- [x] [Args: Command-line argument parsing](#args-parser)
- [x] [Utils: ANSI utility functions](#ansi-utility)
- [ ] Keypass: Binding key input
- [ ] Readline: Waiting for input
- [ ] Prompt: Basic prompt process support and CLI frame handling.
- [ ] Prompt Utils: Advanced commonly used prompt utils
- [ ] Tab: Shell command autocompletion
- [ ] Tab Adapters: Adds tab completion adapters for popular Dart CLI packages.


## Installation

To install the Coal suite, run the following command:

```bash
dart pub add coal
```

## Args Parser

Coal provides a powerful argument parser that allows you to define and parse command-line arguments easily:

```dart
import 'package:coal/args.dart';

final input = const input = ['--a=1','-b','--bool','--no-boop','--multi=foo','--multi=baz','-xyz'];
final args = Args.parse(input);

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

> [!WARNING]
> Coal is currently under development and documentation is not yet ready.

## ANSI Utility

Coal has prepared a series of convenient tools for generating ANSI:

- **[Clear]**: Generate clear ANSI text utility.
- **[Cursor](#cursor)**: Generate cursor operation ANSI text utility.
- **[Erase](#erase)**: Erase ANSI text utility.
- **[Scroll](#scroll)**: Scroll ANSI text utility.
- **[Text](#text)**: Generate text ANSI text utility.

### Clear

| Name | Description |
|:----:|:----|
| `clearScreen()` | Clear the terminal screen. |

### Cursor

| Name | Description |
|:----:|:----|
| `cursorUp([int count = 1])` | Move the cursor up by `count` lines. |
| `cursorDown([int count = 1])` | Move the cursor down by `count` lines. |
| `cursorForward([int count = 1])` | Move the cursor forward by `count` columns. |
| `cursorBackward([int count = 1])` | Move the cursor backward by `count` columns. |
| `cursorNextLine([int count = 1])` | Move the cursor to the next line by `count` lines. |
| `cursorPrevLine([int count = 1])` | Move the cursor to the previous line by `count` lines. |
| `cursorTo(int x, [int? y])` | Move the cursor to the specified position. |
| `cursorMove(int x, int y)` | Move the cursor by `x` columns and `y` lines. |
| `cursorShow` | Show the cursor. |
| `cursorHide` | Hide the cursor. |
| `cursorSave` | Save the cursor position. |
| `cursorRestore` | Restore the cursor position. |
| `cursorLeft` | Move the cursor left by one column. |

### Erase

| Name | Description |
|:----:|:----|
| `eraseScreen` | Erase the entire screen. |
| `eraseLine` | Erase the current line. |
| `eraseLineStart` | Erase from the current cursor position to the beginning of the line. |
| `eraseLineEnd` | Erase from the current cursor position to the end of the line. |
| `eraseUp([int count = 1])` | Erase `count` lines above the current cursor position. |
| `eraseDown([int count = 1])` | Erase `count` lines below the current cursor position. |
| `eraseLines(int count)` | Erase `count` lines above and below the current cursor position. |

### Scroll

| Name | Description |
|:----:|:----|
| `scrollUp([int count = 1])` | Scroll the screen up by `count` lines. |
| `scrollDown([int count = 1])` | Scroll the screen down by `count` lines. |
| `scrollLeft([int count = 1])` | Scroll the screen left by `count` columns. |
| `scrollRight([int count = 1])` | Scroll the screen right by `count` columns. |

### Text

- `stripVTControlCharacters()`: Remove all VT control characters. Use to estimate displayed string width.
- `getTextTruncatedWidth()`: Get the width of a string when truncated to fit within a given width.
- `getTextWidth()`: Get the width of a string.
- `wrapAnsi()`: Wrap a string to fit within a given width.
- `styleText`: Generate a string with ANSI escape codes for styling.

#### Style Text

```dart
// Dart SDK >= 3.10.0
final text = styleText('Hello, World!', [.red]);
// <= 3.10.0
final text = styleText('Hello, World!', [TextStyle.red]);
```

## License

[MIT License](LICENSE)
