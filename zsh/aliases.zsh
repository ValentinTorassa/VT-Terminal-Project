# ========== Navigation ==========
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# ========== Modern replacements ==========
if command -v eza &>/dev/null; then
  alias ls="eza --icons"
  alias ll="eza -la --git --icons"
  alias la="eza -a --icons"
  alias lt="eza --tree --level=2 --icons"
  alias lta="eza --tree --level=2 --icons -a"
fi

if command -v bat &>/dev/null; then
  alias cat="bat --paging=never"
  alias catp="bat --plain"
fi

if command -v rg &>/dev/null; then
  alias grep="rg"
fi

# On Debian/Ubuntu fd-find installs as fdfind
if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
  alias fd="fdfind"
fi

# ========== Git ==========
alias gs="git status"
alias gc="git commit"
alias gp="git push"
alias gpl="git pull"
alias gsw="git switch"
alias lg="lazygit"

# ========== Docker ==========
alias dkps="docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
alias dkc="docker compose"
alias dkcu="docker compose up -d"
alias dkcd="docker compose down"
alias dkcl="docker compose logs -f"
alias dkl="lazydocker"

# ========== System ==========
alias ports="ss -tulnp"
alias myip="curl -s ifconfig.me"
alias dirsize="dust"

# ========== Quick edit ==========
alias zshrc="$EDITOR ~/.zshrc"
alias reload="source ~/.zshrc && echo 'zsh config reloaded'"

# ========== Safety ==========
alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"

# ========== Misc ==========
alias cls="clear"
alias h="history | tail -30"
alias path='echo $PATH | tr ":" "\n" | sort'
alias weather="curl wttr.in/?format=3"
