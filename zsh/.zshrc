# Enable Powerlevel10k instant prompt.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# ---------- Plugins ----------
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  fzf
  sudo
  extract
  copypath
  copyfile
  docker
  docker-compose
  aliases
  web-search
)

source $ZSH/oh-my-zsh.sh

# ---------- PATH ----------
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"

# ---------- Editor ----------
export EDITOR="zed --wait"
export VISUAL="zed --wait"

# ---------- Modular config ----------
# Resolve symlink to find the real directory where the zsh configs live
DOTFILES_ZSH="${${(%):-%x}:A:h}"
[[ -f "$DOTFILES_ZSH/aliases.zsh" ]]      && source "$DOTFILES_ZSH/aliases.zsh"
[[ -f "$DOTFILES_ZSH/functions.zsh" ]]     && source "$DOTFILES_ZSH/functions.zsh"
[[ -f "$DOTFILES_ZSH/ai.zsh" ]]           && source "$DOTFILES_ZSH/ai.zsh"
[[ -f "$DOTFILES_ZSH/keybindings.zsh" ]]  && source "$DOTFILES_ZSH/keybindings.zsh"

# ---------- Tool init ----------
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"
command -v thefuck &>/dev/null && eval "$(thefuck --alias)"
command -v fzf &>/dev/null && {
  export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --info=inline"
  export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
  export FZF_CTRL_T_COMMAND="fd . / --type f --hidden --follow --exclude .git --exclude node_modules --exclude .cache --exclude /proc --exclude /sys --exclude /dev 2>/dev/null"
}

# ---------- Powerlevel10k ----------
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
export DOTFILES_DIR="/home/valen/Documents/GitHub/terminal-project"
