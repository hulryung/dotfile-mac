# ~/.zshrc - managed by dotfile-mac
# zsh port of configs/bash/.bash_profile (macOS default shell is zsh).

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
alias vi=nvim
alias vim=nvim

# ─── Prompt (Starship) ────────────────────────────────────────
# Ghostty injects its shell integration automatically for zsh.
if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
else
    PROMPT='%F{green}%n@%m%f:%F{blue}%~%f%# '
fi

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
