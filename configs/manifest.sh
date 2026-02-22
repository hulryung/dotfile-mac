#!/usr/bin/env bash
# manifest.sh - Config deployment registry
# Format: display_name|source|dest|mode|description

CONFIG_ENTRIES=(
    "Bash Profile|configs/bash/.bash_profile|~/.bash_profile|symlink|Homebrew PATH, aliases (ll, g, gs, gd, gl), 프롬프트"
    "Git Config|configs/git/.gitconfig|~/.gitconfig|copy|defaultBranch=main, pull.rebase, push.autoSetupRemote, aliases (st, co, br, ci, lg)"
    "Starship Config|configs/starship/starship.toml|~/.config/starship.toml|symlink|Gruvbox Rainbow 프리셋"
    "Claude Code Settings|configs/claude/settings.json|~/.claude/settings.json|merge|권한, 팀, 상태줄, 플러그인 설정 (fragment 선택)"
)
