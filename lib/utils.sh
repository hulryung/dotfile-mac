#!/usr/bin/env bash
# utils.sh - Helper functions for dotfile setup

DOTFILE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAILED_PACKAGES=()

# ─── UI Helpers ───────────────────────────────────────────────

print_header() {
    local title="$1"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  $title"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

print_step() {
    echo "  → $1"
}

print_ok() {
    echo "  ✓ $1"
}

print_skip() {
    echo "  [skip] $1"
}

print_fail() {
    echo "  ✗ $1"
}

# ─── Safety Helpers ───────────────────────────────────────────

backup_file() {
    local target="$1"
    if [[ -e "$target" && ! -L "$target" ]]; then
        local backup="${target}.backup.$(date +%Y%m%d%H%M%S)"
        cp -a "$target" "$backup"
        print_step "Backed up: $target → $backup"
    fi
}

# ─── Homebrew Helpers ─────────────────────────────────────────

install_taps() {
    local taps_file="$DOTFILE_DIR/packages/taps.txt"
    [[ ! -f "$taps_file" ]] && return 0

    print_header "Adding Homebrew Taps"

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        local _type name description
        IFS='|' read -r _type name description <<< "$line"
        name="$(echo "$name" | xargs)"
        [[ -z "$name" ]] && continue

        if brew tap | grep -q "^${name}$"; then
            print_skip "$name (already tapped)"
        else
            print_step "Tapping $name..."
            if brew tap "$name" 2>/dev/null; then
                print_ok "$name"
            else
                print_fail "$name"
                FAILED_PACKAGES+=("tap:$name")
            fi
        fi
    done < "$taps_file"
}

install_packages() {
    local category="$1"
    shift
    local packages=("$@")

    [[ ${#packages[@]} -eq 0 ]] && return 0

    print_header "Installing: $category"

    for entry in "${packages[@]}"; do
        local pkg_type pkg_name pkg_desc
        IFS='|' read -r pkg_type pkg_name pkg_desc <<< "$entry"
        pkg_name="$(echo "$pkg_name" | xargs)"
        pkg_type="$(echo "$pkg_type" | xargs)"

        [[ -z "$pkg_name" ]] && continue

        local install_cmd="brew install"

        if [[ "$pkg_type" == "cask" || "$pkg_type" == "font" ]]; then
            install_cmd="brew install --cask"
        fi

        # Check both formula and cask to avoid re-installing
        if brew list --formula "$pkg_name" &>/dev/null || brew list --cask "$pkg_name" &>/dev/null; then
            print_skip "$pkg_name (already installed)"
        else
            print_step "Installing $pkg_name..."
            if $install_cmd "$pkg_name" 2>/dev/null; then
                print_ok "$pkg_name"
            else
                print_fail "$pkg_name"
                FAILED_PACKAGES+=("$pkg_name")
            fi
        fi
    done
}

# ─── Config Deployment ────────────────────────────────────────

deploy_config() {
    local display_name="$1"
    local source="$2"
    local dest="$3"
    local mode="$4"  # symlink | copy | merge

    # Expand ~ in dest
    dest="${dest/#\~/$HOME}"
    source="$DOTFILE_DIR/$source"

    if [[ ! -e "$source" ]]; then
        print_fail "$display_name: source not found ($source)"
        return 1
    fi

    # Ensure destination directory exists
    mkdir -p "$(dirname "$dest")"

    case "$mode" in
        symlink)
            if [[ -L "$dest" && "$(readlink "$dest")" == "$source" ]]; then
                print_skip "$display_name (symlink already correct)"
                return 0
            fi
            backup_file "$dest"
            rm -f "$dest"
            ln -s "$source" "$dest"
            print_ok "$display_name → symlinked"
            ;;
        copy)
            if [[ -f "$dest" ]] && diff -q "$source" "$dest" &>/dev/null; then
                print_skip "$display_name (already up to date)"
                return 0
            fi
            backup_file "$dest"
            cp -a "$source" "$dest"
            print_ok "$display_name → copied"
            ;;
        merge)
            deploy_merged_config "$display_name" "$dest" "$@"
            ;;
        *)
            print_fail "$display_name: unknown mode '$mode'"
            return 1
            ;;
    esac
}

deploy_merged_config() {
    local display_name="$1"
    local dest="$2"
    shift 2
    # Remaining args: fragment files to merge
    local fragments=("$@")

    if ! command -v jq &>/dev/null; then
        print_fail "$display_name: jq is required for JSON merge"
        return 1
    fi

    if [[ ${#fragments[@]} -eq 0 ]]; then
        print_skip "$display_name (no fragments selected)"
        return 0
    fi

    # Start with empty object or existing file
    local result="{}"
    if [[ -f "$dest" ]]; then
        result="$(cat "$dest")"
    fi

    for frag in "${fragments[@]}"; do
        local frag_path="$DOTFILE_DIR/$frag"
        if [[ -f "$frag_path" ]]; then
            result="$(echo "$result" | jq -s '.[0] * .[1]' - "$frag_path")"
        else
            print_fail "Fragment not found: $frag"
        fi
    done

    backup_file "$dest"
    mkdir -p "$(dirname "$dest")"
    echo "$result" | jq '.' > "$dest"
    print_ok "$display_name → merged (${#fragments[@]} fragments)"
}

# ─── Summary ──────────────────────────────────────────────────

print_summary() {
    print_header "Setup Complete"

    if [[ ${#FAILED_PACKAGES[@]} -gt 0 ]]; then
        echo "  ⚠ Failed packages:"
        for pkg in "${FAILED_PACKAGES[@]}"; do
            echo "    - $pkg"
        done
        echo ""
    fi

    echo "  Done! You may need to restart your terminal."
}
