# Coal Examples

## <TAB>

Setup:
```bash
git clone https://github.com/medz/coal.git
cd coal && dart pub get && cd example
export PATH="$(pwd):$PATH"
dart compile exe tab.dart --output=tab

# bash
source <(tab complete bash)

# zsh
source <(tab complete zsh)

# fish, Remember to delete it after you finish your experience!
tab complete fish > ~/.config/fish/completions/tab.fish

# powershell
tab complete powershell > ~/.tab-completion.ps1
echo '. ~/.tab-completion.ps1' > $PROFILE
```

### Try <TAB>

```bash
tab <TAB>
```
