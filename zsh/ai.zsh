# ========== AI Shell Helper ==========
# Uses the Anthropic API to suggest commands.
# Set VT_ANTHROPIC_KEY in your environment to enable.

ai() {
  if [[ -z "$VT_ANTHROPIC_KEY" ]]; then
    echo "Set VT_ANTHROPIC_KEY to use the AI assistant"
    echo "export VT_ANTHROPIC_KEY='your-key-here'"
    return 1
  fi

  local question="$*"
  if [[ -z "$question" ]]; then
    echo "Usage: ai <question>"
    echo "Example: ai how do I find files larger than 100MB"
    return 1
  fi

  local os_info
  if [[ "$(uname)" == "Darwin" ]]; then
    os_info="macOS $(sw_vers -productVersion)"
  else
    os_info="Linux $(uname -r)"
  fi

  local response
  response=$(curl -s https://api.anthropic.com/v1/messages \
    -H "x-api-key: $VT_ANTHROPIC_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d "$(jq -n \
      --arg q "$question" \
      --arg os "$os_info" \
      --arg shell "zsh" \
      '{
        model: "claude-haiku-4-5-20251001",
        max_tokens: 1024,
        messages: [{
          role: "user",
          content: "You are a terminal command assistant. The user is on \($os) using \($shell). Give a concise answer with the command(s) needed. Format: show the command first in a code block, then a one-line explanation. Be brief.\n\nQuestion: \($q)"
        }]
      }'
    )")

  local text
  text=$(printf '%s' "$response" | jq -r '.content[0].text // .error.message // "Error: unexpected response"')
  echo "$text"
}

# Capture last command output automatically
VT_LAST_OUTPUT="/tmp/vt_last_output_${$}"

_vt_preexec() {
  [[ "$1" =~ ^(ai|aiexplain|aicommit|claude|codex|gemini|antigravity|exec|exit|clear|cd|ls|history) ]] && return
  : > "$VT_LAST_OUTPUT"
  exec {_VT_OUT_FD}>&1
  exec 1> >(tee "$VT_LAST_OUTPUT" >&$_VT_OUT_FD 2>/dev/null)
}

_vt_precmd() {
  [[ -v _VT_OUT_FD ]] || return
  exec 1>&$_VT_OUT_FD
  unset _VT_OUT_FD
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec _vt_preexec
add-zsh-hook precmd _vt_precmd

# Explain last command output or piped input
# Usage: aiexplain [question]
#        cat error.log | aiexplain "what went wrong"
aiexplain() {
  if [[ -z "$VT_ANTHROPIC_KEY" ]]; then
    echo "Set VT_ANTHROPIC_KEY to use the AI assistant"
    return 1
  fi

  local question="${1:-explain this output}"
  local input

  if [[ -t 0 ]]; then
    if [[ -s "$VT_LAST_OUTPUT" ]]; then
      input=$(cat "$VT_LAST_OUTPUT")
    else
      echo "No output captured. Run a command first or pipe output: cmd | aiexplain"
      return 1
    fi
  else
    input=$(cat)
  fi

  local response
  response=$(curl -s https://api.anthropic.com/v1/messages \
    -H "x-api-key: $VT_ANTHROPIC_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d "$(jq -n \
      --arg q "$question" \
      --arg input "$input" \
      '{
        model: "claude-haiku-4-5-20251001",
        max_tokens: 1024,
        messages: [{
          role: "user",
          content: "You are a terminal output analyst. Be concise and practical.\n\nUser question: \($q)\n\nTerminal output:\n\($input)"
        }]
      }'
    )")

  printf '%s' "$response" | jq -r '.content[0].text // .error.message // "Error: unexpected response"'
}

# AI-powered git commit message generator
aicommit() {
  if [[ -z "$VT_ANTHROPIC_KEY" ]]; then
    echo "Set VT_ANTHROPIC_KEY to use the AI assistant"
    return 1
  fi

  local diff
  diff=$(git diff --staged)
  if [[ -z "$diff" ]]; then
    echo "No staged changes. Stage files first with: git add <files>"
    return 1
  fi

  local response
  response=$(curl -s https://api.anthropic.com/v1/messages \
    -H "x-api-key: $VT_ANTHROPIC_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d "$(jq -n \
      --arg diff "$diff" \
      '{
        model: "claude-haiku-4-5-20251001",
        max_tokens: 256,
        messages: [{
          role: "user",
          content: "Generate a concise git commit message for this diff. Use conventional commits format (feat:, fix:, refactor:, etc). One line only, max 72 chars. No quotes around the message. Just the message, nothing else.\n\nDiff:\n\($diff)"
        }]
      }'
    )")

  local msg
  msg=$(printf '%s' "$response" | jq -r '.content[0].text // empty')
  if [[ -z "$msg" ]]; then
    echo "Failed to generate commit message"
    return 1
  fi

  echo "Suggested commit message:"
  echo "  $msg"
  echo ""
  read -r "confirm?Use this message? [Y/n/e(dit)] "
  case "$confirm" in
    n|N) echo "Aborted" ;;
    e|E)
      read -r "edited?Edit message: " -i "$msg"
      git commit -m "$edited"
      ;;
    *)
      git commit -m "$msg"
      ;;
  esac
}

# AI command suggestion with Alt+A
_ai_suggest_widget() {
  local buffer="$BUFFER"
  if [[ -z "$buffer" || -z "$VT_ANTHROPIC_KEY" ]]; then
    return
  fi

  zle -M "Thinking..."

  local response
  response=$(curl -s https://api.anthropic.com/v1/messages \
    -H "x-api-key: $VT_ANTHROPIC_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d "$(jq -n \
      --arg q "$buffer" \
      '{
        model: "claude-haiku-4-5-20251001",
        max_tokens: 200,
        messages: [{
          role: "user",
          content: "The user typed this in their zsh terminal and wants you to complete or fix it. Return ONLY the corrected/completed command. No explanation, no markdown, no backticks. Just the raw command.\n\nInput: \($q)"
        }]
      }'
    )")

  local cmd
  cmd=$(printf '%s' "$response" | jq -r '.content[0].text // empty')
  if [[ -n "$cmd" ]]; then
    BUFFER="$cmd"
    CURSOR=${#BUFFER}
    zle -M "AI suggestion applied"
  else
    zle -M "No suggestion available"
  fi
  zle redisplay
}

zle -N _ai_suggest_widget
bindkey '^[a' _ai_suggest_widget
