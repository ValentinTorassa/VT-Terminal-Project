# ========== Custom Keybindings ==========

# Ctrl+F: fuzzy find files and open in editor
_fzf_edit_widget() {
  local file
  file=$(fd --type f --hidden --follow --exclude .git 2>/dev/null | fzf --height 40% --reverse --preview 'bat --color=always --line-range :50 {} 2>/dev/null || cat {}')
  if [[ -n "$file" ]]; then
    BUFFER="${EDITOR:-vim} $file"
    zle accept-line
  fi
  zle redisplay
}
zle -N _fzf_edit_widget
bindkey '^F' _fzf_edit_widget

# Ctrl+G: launch lazygit
_lazygit_widget() {
  lazygit
  zle redisplay
}
zle -N _lazygit_widget
bindkey '^G' _lazygit_widget

# Ctrl+X Ctrl+D: launch lazydocker
_lazydocker_widget() {
  lazydocker
  zle redisplay
}
zle -N _lazydocker_widget
bindkey '^X^D' _lazydocker_widget
