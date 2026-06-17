# Coal Examples

Basic setup:

```bash
git clone https://github.com/medz/coal.git
cd coal && dart pub get && cd example
export PATH="$(pwd):$PATH"
```

## \<TAB\>

Setup:

```bash
dart compile exe tab.dart --output=tab

# bash
source <(tab complete bash)

# zsh
autoload -Uz compinit && compinit
source <(tab complete zsh)

# fish, Remember to delete it after you finish your experience!
tab complete fish > ~/.config/fish/completions/tab.fish

# powershell
tab complete powershell > ~/.tab-completion.ps1
Add-Content -Path $PROFILE -Value '. ~/.tab-completion.ps1'
```

### Try \<TAB\>

```bash
tab <TAB>
```

## `args` Adapter

```bash
dart compile exe args_example.dart --output=args_example

# bash
source <(args_example complete bash)

# zsh
autoload -Uz compinit && compinit
source <(args_example complete zsh)

# fish, Remember to delete it after you finish your experience!
args_example complete fish > ~/.config/fish/completions/args_example.fish

# powershell
args_example complete powershell > ~/.args_example-completion.ps1
Add-Content -Path $PROFILE -Value '. ~/.args_example-completion.ps1'
```

Try it:

```bash
args_example <TAB>
```
