# ~/.bash_profile - managed by dotfile-mac

# ─── Ghostty Shell Integration ──────────────────────────────
if [ -n "${GHOSTTY_RESOURCES_DIR}" ]; then
  builtin source "${GHOSTTY_RESOURCES_DIR}/shell-integration/bash/ghostty.bash"
fi

# ─── Silence macOS zsh warning ──────────────────────────────
export BASH_SILENCE_DEPRECATION_WARNING=1

# ─── Homebrew ─────────────────────────────────────────────────
export HOMEBREW_NO_ENV_HINTS=1

if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# ─── Path ─────────────────────────────────────────────────────
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
export DOTNET_ROOT="$HOME/.dotnet"
export DOTNET_ROOT_ARM64="$DOTNET_ROOT"

case ":$PATH:" in
    *":$DOTNET_ROOT:"*) ;;
    *) export PATH="$DOTNET_ROOT:$PATH" ;;
esac

# ─── Editor ───────────────────────────────────────────────────
export EDITOR="vim"

# ─── Aliases ──────────────────────────────────────────────────
alias ll='ls -la'
alias la='ls -A'
alias g='git'
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline -20'

# ─── Prompt (Starship) ────────────────────────────────────────
if command -v starship &>/dev/null; then
    eval "$(starship init bash)"
else
    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
fi

alias vi=nvim
alias vim=nvim

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
