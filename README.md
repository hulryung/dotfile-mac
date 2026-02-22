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
│   ├── taps.txt          # Homebrew taps
│   ├── ai-tools.txt      # AI CLI tools
│   ├── cli-tools.txt     # CLI utilities
│   ├── custom-tools.txt  # hulryung/tap packages
│   ├── apps.txt          # GUI apps (casks)
│   └── fonts.txt         # Fonts
└── configs/
    ├── manifest.sh       # Config deployment registry
    ├── claude/            # Claude Code settings
    │   ├── settings.json  # Full template (fallback)
    │   └── fragments/     # Granular settings (merged with jq)
    ├── bash/              # Shell config
    └── git/               # Git config
```

## How It Works

### Setup Flow

1. Homebrew 설치 (없으면)
2. `gum` 설치 (없으면, bash fallback 포함)
3. Homebrew bash를 기본 쉘로 변경 (확인 후)
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
├── permissions.json   # 권한 설정
├── statusline.json    # 상태줄 설정
└── ui.json            # UI 설정
```

## Features

- **Idempotent**: 재실행 시 이미 설치된 것은 skip
- **Safe**: 기존 설정은 backup 후 덮어쓰기
- **Interactive**: gum TUI로 선택 (없으면 bash fallback)
- **Extensible**: 패키지는 한 줄, 설정은 manifest에 한 줄 추가
