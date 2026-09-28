# ############################## PATHS & ENV ##############################

export ZSH="$HOME/.oh-my-zsh"
export ZSH_CUSTOM="$HOME/.config/@zsh-custom"

export EDITOR='fresh'

export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"
export PATH="$HOME/.opencode/bin:$PATH"
export PATH="$HOME/.lmstudio/bin:$PATH"
export PATH="$PATH:/opt/intellij-idea/bin"

# Linuxbrew
if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# NVM
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"


# ############################## HISTORY #################################

HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS

HIST_STAMPS="mm/dd/yyyy"


# ############################## OH MY ZSH ###############################

# No OMZ theme — Oh My Posh owns the prompt.
ZSH_THEME=""

plugins=(
    git
    zsh-autosuggestions
)

source "$ZSH/oh-my-zsh.sh"


# ############################## SYNTAX HIGHLIGHTING #####################

# Catppuccin colors/config, if present.
[[ -f "$ZSH_CUSTOM/catppuccin_mocha-zsh-syntax-highlighting.zsh" ]] &&
    source "$ZSH_CUSTOM/catppuccin_mocha-zsh-syntax-highlighting.zsh"

# Fast Syntax Highlighting.
[[ -f "$ZSH_CUSTOM/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ]] &&
    source "$ZSH_CUSTOM/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"


# ############################## OH MY POSH ##############################

if command -v oh-my-posh >/dev/null 2>&1; then
    eval "$(oh-my-posh init zsh --config "$HOME/.config/ohmyposh/zen.toml")"
fi


# ############################## ALIASES #################################

alias ff="fastfetch"
alias hw="hwinfo --short"
alias files="yazi"

alias hothmount='sshfs nitro@192.168.1.154:/home/nitro ~/nebulon \
-o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3'

alias hothunmount='fusermount3 -u ~/nebulon'

alias storagereport="~/scripts/storage-report.sh"
alias screenshots-sort="~/scripts/screenshots-sort.sh"
alias downloads-clean="~/scripts/downloads-clean.sh"
alias clock="~/scripts/clock-check.sh"
alias clock-fix="~/scripts/school-time-fix.sh"


# ############################## AUTOSUGGESTIONS #########################

bindkey '^I' autosuggest-accept

ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(
    buffer-empty
    bracketed-paste
    accept-line
    push-line-or-edit
)

ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_USE_ASYNC=true