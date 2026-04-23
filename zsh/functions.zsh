# Create a directory and cd into it
mkcd() { mkdir -p "$1" && cd "$1"; }

# Extract any archive
ex() {
  if [[ -f "$1" ]]; then
    case "$1" in
      *.tar.bz2) tar xjf "$1" ;;
      *.tar.gz)  tar xzf "$1" ;;
      *.tar.xz)  tar xJf "$1" ;;
      *.bz2)     bunzip2 "$1" ;;
      *.gz)      gunzip "$1" ;;
      *.tar)     tar xf "$1" ;;
      *.tbz2)    tar xjf "$1" ;;
      *.tgz)     tar xzf "$1" ;;
      *.zip)     unzip "$1" ;;
      *.7z)      7z x "$1" ;;
      *.rar)     unrar x "$1" ;;
      *)         echo "'$1' cannot be extracted" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Fuzzy kill process
fkill() {
  local pid
  pid=$(ps aux | fzf --header='Select process to kill' | awk '{print $2}')
  [[ -n "$pid" ]] && kill -9 "$pid" && echo "Killed PID $pid"
}

# Quick HTTP server in current directory
serve() {
  local port="${1:-8000}"
  echo "Serving on http://localhost:$port"
  python3 -m http.server "$port"
}

# Docker shell into a running container
dksh() {
  local container
  container=$(docker ps --format '{{.Names}}' | fzf --header='Select container')
  [[ -n "$container" ]] && docker exec -it "$container" /bin/sh
}

# Cheatsheet viewer (integrates with cheatsheet system)
cheat() {
  local cheatdir="${DOTFILES_DIR:-$HOME/.dotfiles}/cheatsheet"
  if [[ -n "$1" ]]; then
    local file="$cheatdir/$1.md"
    if [[ -f "$file" ]]; then
      if command -v glow &>/dev/null; then
        glow -p "$file"
      else
        cat "$file"
      fi
    else
      echo "No cheatsheet for '$1'. Available:"
      ls "$cheatdir"/*.md 2>/dev/null | xargs -I{} basename {} .md
    fi
  else
    local sheet
    sheet=$(ls "$cheatdir"/*.md 2>/dev/null | xargs -I{} basename {} .md | fzf --header='Select cheatsheet')
    [[ -n "$sheet" ]] && cheat "$sheet"
  fi
}

# Quick cheatsheet add
cheat-add() {
  local category="$1" shortcut="$2" description="$3"
  local cheatdir="${DOTFILES_DIR:-$HOME/.dotfiles}/cheatsheet"
  if [[ -z "$category" || -z "$shortcut" || -z "$description" ]]; then
    echo "Usage: cheat-add <category> <shortcut> <description>"
    echo "Example: cheat-add git 'Ctrl+G' 'Open lazygit'"
    return 1
  fi
  echo "| \`$shortcut\` | $description |" >> "$cheatdir/$category.md"
  echo "Added to $category cheatsheet"
}
