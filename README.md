# dotfile-mac

macOS 새 Mac 설정 자동화 dotfile 시스템. Homebrew 기반 패키지 설치 + 설정 파일 배포를 `gum` TUI로 인터랙티브하게 선택.

## Quick Start

```bash
bash setup.sh
```

## Structure

```
dotfile-mac/
├── setup.sh              # Main entry point
├── lib/
│   ├── utils.sh          # Helper functions
│   └── gum.sh            # gum TUI wrappers + bash fallback
├── packages/
│   ├── taps.txt          # Homebrew taps (hulryung/tap, hulryung/xcli)
│   ├── ai-tools.txt      # AI CLI tools (claude-code, codex, gemini-cli)
│   ├── cli-tools.txt     # CLI utilities (jq, colima, starship, ...)
│   ├── custom-tools.txt  # hulryung packages (xcli, hangulkeychanger, ...)
│   ├── apps.txt          # GUI apps (google-drive, raycast, iterm2, ...)
│   └── fonts.txt         # Fonts (D2Coding Nerd Font)
└── configs/
    ├── manifest.sh       # Config deployment registry
    ├── bash/              # .bash_profile (Homebrew, starship, aliases)
    ├── git/               # .gitconfig (rebase, autoSetupRemote, aliases)
    ├── starship/          # starship.toml (Gruvbox Rainbow preset)
    └── claude/            # Claude Code settings
        ├── settings.json  # Full template (fallback)
        └── fragments/     # Granular settings (merged with jq)
```

## How It Works

### Setup Flow

1. Homebrew 설치 (없으면)
2. `gum` 설치 (없으면, bash fallback 포함)
3. `/bin/bash`를 기본 쉘로 변경 (확인 후)
4. Homebrew taps 추가
5. 카테고리별 패키지 선택 → 설치
6. 설정 파일 선택 → 배포
7. 완료 요약

### Adding Packages

패키지 파일에 한 줄 추가:

```
# Format: type|name|description
formula|my-tool|My awesome tool
cask|my-app|My GUI application
```

### Config Modes

| Mode | Description |
|------|-------------|
| `symlink` | 원본 링크 (변경사항 자동 반영) |
| `copy` | 파일 복사 |
| `merge` | JSON fragments를 `jq`로 deep merge |

### Claude Code Settings

`configs/claude/fragments/` 디렉토리에 JSON 조각을 추가하면 선택적으로 병합:

```
fragments/
├── permissions.json   # bypassPermissions, 위험모드 skip, Co-Author 미표시
├── teams.json         # Agent Teams 활성화, tmux 모드
└── statusline.json    # cc-statusline 커맨드 기반 상태줄
```

### Starship Prompt

[Gruvbox Rainbow](https://starship.rs/presets/gruvbox-rainbow) 프리셋 사용. D2Coding Nerd Font 필요.

## Features

- **Idempotent**: 재실행 시 이미 설치된 것은 skip
- **Safe**: 기존 설정은 backup 후 덮어쓰기
- **Interactive**: gum TUI로 선택 (없으면 bash fallback)
- **Extensible**: 패키지는 한 줄, 설정은 manifest에 한 줄 추가
