# ~/.bash_profile - managed by dotfile-mac

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
export PATH="$HOME/.local/bin:$PATH"

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
