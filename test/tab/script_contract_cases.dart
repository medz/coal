import 'package:coal/tab.dart';

import '_def.dart';

enum ContractShell { bash, zsh, fish, powershell }

extension ContractShellScripts on ContractShell {
  String generate(String commandName, String execCommand) {
    return switch (this) {
      ContractShell.bash => Shell.bash.generate(commandName, execCommand),
      ContractShell.zsh => Shell.zsh.generate(commandName, execCommand),
      ContractShell.fish => Shell.fish.generate(commandName, execCommand),
      ContractShell.powershell => Shell.powershell.generate(
        commandName,
        execCommand,
      ),
    };
  }
}

class ShellScriptExpectations {
  const ShellScriptExpectations({this.contains = const <String>[]});

  final List<String> contains;
}

class ScriptContractCase {
  const ScriptContractCase({
    required this.key,
    required this.description,
    this.commandName = name,
    this.execCommand = exec,
    required this.shellExpectations,
  });

  final String key;
  final String description;
  final String commandName;
  final String execCommand;
  final Map<ContractShell, ShellScriptExpectations> shellExpectations;

  ShellScriptExpectations expectationsFor(ContractShell shell) {
    final expectations = shellExpectations[shell];
    if (expectations == null) {
      throw StateError('Case $key does not define expectations for $shell');
    }
    return expectations;
  }
}

final List<ScriptContractCase> scriptContractCases = <ScriptContractCase>[
  ScriptContractCase(
    key: 'core-shell-behavior',
    description: 'includes core completion behavior snippets',
    shellExpectations: <ContractShell, ShellScriptExpectations>{
      ContractShell.bash: ShellScriptExpectations(
        contains: <String>[
          'requestComp="$exec complete --',
          'if [[ \$((directive & \$ShellCompDirectiveError)) -ne 0 ]]',
          'if [[ \$((directive & \$ShellCompDirectiveNoSpace)) -ne 0 ]]',
          'if [[ \$((directive & \$ShellCompDirectiveKeepOrder)) -ne 0 ]]',
          'if [[ \$((directive & \$ShellCompDirectiveNoFileComp)) -ne 0 ]]',
          'if [[ \$((directive & \$ShellCompDirectiveFilterFileExt)) -ne 0 ]]',
          'if [[ \$((directive & \$ShellCompDirectiveFilterDirs)) -ne 0 ]]',
          'if [[ "\$directive" == "\$out" ]]; then',
          'if [[ "\$cur" == -*=* ]]; then',
          'if [[ \$(type -t compopt) == builtin ]]; then',
          '\${BASH_VERSINFO[0]} -gt 4',
        ],
      ),
      ContractShell.zsh: ShellScriptExpectations(
        contains: <String>[
          'return 1',
          'if eval _describe \$keepOrder "completions" completions \${flagPrefix} \${noSpace}; then',
          'completions from _describe; this allows other matching algorithms.',
        ],
      ),
      ContractShell.fish: ShellScriptExpectations(
        contains: <String>[
          'set -l requestComp "$exec complete -- \$args[2..-1] \$last_arg"',
          r'if test (math "$directive_num & $ShellCompDirectiveError") -ne 0',
          r'if test (math "$directive_num & $ShellCompDirectiveNoFileComp") -eq 0',
          'set -l flag_prefix (string match -r -- \'-.*=\' "\$last_arg")',
        ],
      ),
      ContractShell.powershell: ShellScriptExpectations(
        contains: <String>[
          '\$ExecutionContext.SessionState.LanguageMode -eq "FullLanguage"',
          '\$CompletionText = \$(\$comp.Name | __${name}_escapeStringWithSpecialChars) + \$Space',
          '\$CompletionText = "\$(\$comp.Name)\$Description"',
        ],
      ),
    },
  ),
  ScriptContractCase(
    key: 'special-command-name',
    description: 'handles special characters in command names',
    commandName: specialName,
    shellExpectations: <ContractShell, ShellScriptExpectations>{
      ContractShell.bash: ShellScriptExpectations(
        contains: <String>[
          '__${escapedName}_debug()',
          '__${escapedName}_complete()',
          'complete -F __${escapedName}_complete $specialName',
        ],
      ),
      ContractShell.zsh: ShellScriptExpectations(
        contains: <String>[
          '#compdef $specialName',
          'compdef _$escapedName $specialName',
          '__${escapedName}_debug()',
          '_$escapedName()',
        ],
      ),
      ContractShell.fish: ShellScriptExpectations(
        contains: <String>[
          'function __${escapedName}_debug',
          'function __${escapedName}_perform_completion',
          'complete -c $specialName -f -a "(eval __${escapedName}_perform_completion)"',
        ],
      ),
      ContractShell.powershell: ShellScriptExpectations(
        contains: <String>[
          'function __${escapedName}_debug',
          'filter __${escapedName}_escapeStringWithSpecialChars',
          '[scriptblock]\$__${escapedName}CompleterBlock',
          "Register-ArgumentCompleter -CommandName '$specialName'",
        ],
      ),
    },
  ),
];

Iterable<ScriptContractCase> scriptContractCasesFor(ContractShell shell) sync* {
  for (final contractCase in scriptContractCases) {
    if (contractCase.shellExpectations.containsKey(shell)) {
      yield contractCase;
    }
  }
}
