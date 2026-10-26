# Agent shells (Claude Code sets CLAUDECODE, Codex sets CODEX_THREAD_ID) skip the
# human-only aliases below: icons, prompts and pagers break unattended commands.
_vt_human_shell() { [[ -z $CLAUDECODE && -z $CODEX_THREAD_ID && -z $CODEX_SANDBOX ]] }

# ========== Navigation ==========
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# ========== Modern replacements ==========
if _vt_human_shell && command -v eza &>/dev/null; then
  alias ls="eza --icons=always"
  alias ll="eza -la --git --icons=always"
  alias la="eza -a --icons=always"
  alias lt="eza --tree --level=2 --icons=always"
  alias lta="eza --tree --level=2 --icons=always -a"
fi

if _vt_human_shell && command -v bat &>/dev/null; then
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
alias ghb="gh browse"
alias gdm="git diff main...HEAD | delta"

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
if _vt_human_shell; then
  alias rm="rm -i"
  alias cp="cp -i"
  alias mv="mv -i"
fi

# ========== Misc ==========
alias cls="clear"
alias h="history | tail -30"
alias path='echo $PATH | tr ":" "\n" | sort'
alias weather="curl wttr.in/?format=3"
