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
  const ShellScriptExpectations({
    this.contains = const <String>[],
    this.absent = const <String>[],
  });

  final List<String> contains;
  final List<String> absent;
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
          "requestComp=('/usr/bin/dart' '/path/to/testcli' complete --)",
          'requestComp+=("\$arg")',
          'out=\$("\${requestComp[@]}" 2>/dev/null)',
          'local shellCompDirectiveError=',
          'if [[ \$((directive & shellCompDirectiveError)) -ne 0 ]]',
          'if [[ \$((directive & shellCompDirectiveNoSpace)) -ne 0 ]]',
          'if [[ \$((directive & shellCompDirectiveKeepOrder)) -ne 0 ]]',
          'if [[ \$((directive & shellCompDirectiveNoFileComp)) -ne 0 ]]',
          'if [[ \$((directive & shellCompDirectiveFilterFileExt)) -ne 0 ]]',
          'if [[ \$((directive & shellCompDirectiveFilterDirs)) -ne 0 ]]',
          'if [[ "\$directive" == "\$out" ]]; then',
          'if [[ "\$cur" == -*=* ]]; then',
          'if [[ \$(type -t compopt) == builtin ]]; then',
          '\${BASH_VERSINFO[0]} -gt 4',
        ],
        absent: <String>['eval "\$requestComp"', "printf -v arg '%q'"],
      ),
      ContractShell.zsh: ShellScriptExpectations(
        contains: <String>[
          "requestComp=('/usr/bin/dart' '/path/to/testcli' complete --)",
          'requestComp+=("\${completion_args[@]}")',
          'out=\$("\${requestComp[@]}" 2>/dev/null)',
          'local -a completions requestComp describeFlagPrefix describeNoSpace describeKeepOrder',
          'describeFlagPrefix=(-P "\${BASH_REMATCH}")',
          "describeNoSpace=(-S '')",
          'describeKeepOrder=(-V)',
          'if _describe "\${describeKeepOrder[@]}" "completions" completions "\${describeFlagPrefix[@]}" "\${describeNoSpace[@]}"; then',
          'return 1',
          'completions from _describe; this allows other matching algorithms.',
        ],
        absent: <String>['out=\$(eval \${requestComp}', 'eval _describe'],
      ),
      ContractShell.fish: ShellScriptExpectations(
        contains: <String>[
          "set -l requestComp '/usr/bin/dart' '/path/to/testcli' complete --",
          'set -a requestComp "\$arg"',
          'set -l results (\$requestComp 2> /dev/null)',
          r'if test (math "$directive_num & $ShellCompDirectiveError") -ne 0',
          r'if test (math "$directive_num & $ShellCompDirectiveNoFileComp") -eq 0',
          'set -l flag_prefix (string match -r -- \'-.*=\' "\$last_arg")',
        ],
        absent: <String>['eval \$requestComp'],
      ),
      ContractShell.powershell: ShellScriptExpectations(
        contains: <String>[
          '\$RequestComp = @(\'/usr/bin/dart\', \'/path/to/testcli\', "complete", "--")',
          '\$CommandAst.CommandElements | Where-Object { \$_.Extent.StartOffset -lt \$CursorPosition }',
          '\$CompletionArgs += __${name}_commandElementValue',
          '\$RequestComp += \$CompletionArgs',
          '\$NativeArgumentPassing = Get-Variable -Name PSNativeCommandArgumentPassing -ErrorAction SilentlyContinue',
          '\$LegacyNativeArgs = (\$PSVersionTable.PSVersion.Major -lt 6) -or (',
          '\$NativeArgumentPassing.Value -eq "Legacy"',
          'if (\$_ -eq "") { \'""\' } else { \$_ }',
          '\$Out = @(& \$RequestComp[0] @RequestArgs 2>\$null)',
          '\$DirectiveLine = [string]\$Out[-1]',
          '\$Out = @()',
          '\$ExecutionContext.SessionState.LanguageMode -eq "FullLanguage"',
          '\$CompletionText = \$(\$comp.Name | __${name}_escapeStringWithSpecialChars) + \$Space',
          '\$CompletionText = "\$(\$comp.Name)\$Description"',
        ],
        absent: <String>[
          'Invoke-Expression',
          'filter __${name}_quoteArgument',
          '\$Arguments.Split(" ")',
          '\$Out = & \$RequestComp[0] @RequestArgs 2>\$null',
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
