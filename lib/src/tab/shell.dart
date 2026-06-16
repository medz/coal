import 'scripts/bash.dart';
import 'scripts/fish.dart';
import 'scripts/powershell.dart';
import 'scripts/zsh.dart';

enum Shell {
  bash(bashScript),
  fish(fishScript),
  powershell(powershellScript),
  zsh(zshScript);

  const Shell(this.generate);

  /// Generates a completion setup script for [name].
  ///
  /// [exec] is parsed as a shell-style command prefix, then re-quoted by the
  /// generated script before completion arguments are appended.
  final String Function(String name, String exec) generate;
}
