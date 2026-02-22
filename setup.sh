#!/usr/bin/env bash
set -euo pipefail

DOTFILE_DIR="$(cd "$(dirname "$0")" && pwd)"

source "$DOTFILE_DIR/lib/utils.sh"
source "$DOTFILE_DIR/lib/gum.sh"

# ─── 1. Homebrew ──────────────────────────────────────────────

print_header "Checking Homebrew"

if command -v brew &>/dev/null; then
    print_skip "Homebrew already installed"
else
    print_step "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Set up PATH for this session
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    print_ok "Homebrew installed"
fi

# ─── 2. gum ──────────────────────────────────────────────────

if ! command -v gum &>/dev/null; then
    print_step "Installing gum for interactive UI..."
    if brew install gum 2>/dev/null; then
        HAS_GUM=true
        print_ok "gum installed"
    else
        print_fail "gum installation failed, using bash fallback"
    fi
else
    print_skip "gum already installed"
fi

# ─── 3. Default Shell ────────────────────────────────────────

print_header "Default Shell"

current_shell="$(dscl . -read /Users/"$(whoami)" UserShell | awk '{print $2}')"

if [[ "$current_shell" == "/bin/bash" ]]; then
    print_skip "Default shell is already /bin/bash"
else
    if gum_confirm "Change default shell to /bin/bash?"; then
        chsh -s /bin/bash
        print_ok "Default shell changed to /bin/bash"
    else
        print_skip "Keeping current shell: $current_shell"
    fi
fi

# ─── 4. Taps ─────────────────────────────────────────────────

install_taps

# ─── 5. Packages ─────────────────────────────────────────────

PACKAGE_CATEGORIES=(
    "AI Tools|$DOTFILE_DIR/packages/ai-tools.txt"
    "CLI Tools|$DOTFILE_DIR/packages/cli-tools.txt"
    "Custom Tools|$DOTFILE_DIR/packages/custom-tools.txt"
    "GUI Apps|$DOTFILE_DIR/packages/apps.txt"
    "Fonts|$DOTFILE_DIR/packages/fonts.txt"
)

for cat_entry in "${PACKAGE_CATEGORIES[@]}"; do
    IFS='|' read -r cat_name cat_file <<< "$cat_entry"

    [[ ! -f "$cat_file" ]] && continue

    if gum_confirm "Install $cat_name?"; then
        selected=()
        while IFS= read -r line; do
            [[ -n "$line" ]] && selected+=("$line")
        done < <(select_packages "$cat_name" "$cat_file")

        install_packages "$cat_name" "${selected[@]}"
    else
        print_skip "$cat_name (skipped)"
    fi
done

# ─── 6. Config Files ─────────────────────────────────────────

print_header "Config Deployment"

source "$DOTFILE_DIR/configs/manifest.sh"

if gum_confirm "Deploy config files?"; then
    selected_configs=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && selected_configs+=("$line")
    done < <(select_configs "${CONFIG_ENTRIES[@]}")

    for config_entry in "${selected_configs[@]}"; do
        IFS='|' read -r display_name source dest mode <<< "$config_entry"

        if [[ "$mode" == "merge" && "$display_name" == "Claude Code Settings" ]]; then
            # Special handling: select fragments then merge
            print_step "Configuring $display_name..."

            fragments_dir="$DOTFILE_DIR/configs/claude/fragments"
            selected_frags=()
            while IFS= read -r frag; do
                [[ -n "$frag" ]] && selected_frags+=("configs/claude/fragments/$frag")
            done < <(select_claude_fragments "$fragments_dir")

            if [[ ${#selected_frags[@]} -gt 0 ]]; then
                dest="${dest/#\~/$HOME}"
                deploy_merged_config "$display_name" "$dest" "${selected_frags[@]}"
            else
                # Fallback: copy the full settings.json
                if gum_confirm "No fragments selected. Deploy full settings.json instead?"; then
                    deploy_config "$display_name" "$source" "$dest" "copy"
                fi
            fi
        else
            deploy_config "$display_name" "$source" "$dest" "$mode"
        fi
    done
else
    print_skip "Config deployment skipped"
fi

# ─── 7. Summary ──────────────────────────────────────────────

print_summary
