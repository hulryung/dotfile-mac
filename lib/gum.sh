#!/usr/bin/env bash
# gum.sh - gum TUI wrappers with bash fallback

HAS_GUM=false
command -v gum &>/dev/null && HAS_GUM=true

# ─── Confirm Prompt ──────────────────────────────────────────

gum_confirm() {
    local prompt="$1"
    local default="${2:-yes}"  # yes or no

    if $HAS_GUM; then
        if [[ "$default" == "yes" ]]; then
            gum confirm "$prompt" --default=yes
        else
            gum confirm "$prompt" --default=no
        fi
    else
        local yn
        if [[ "$default" == "yes" ]]; then
            read -rp "  $prompt [Y/n] " yn
            [[ -z "$yn" || "$yn" =~ ^[Yy] ]]
        else
            read -rp "  $prompt [y/N] " yn
            [[ "$yn" =~ ^[Yy] ]]
        fi
    fi
}

# ─── Package Selection ───────────────────────────────────────

# Parse a package file and return entries
# Format: type|name|description
parse_package_file() {
    local file="$1"
    local entries=()

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        entries+=("$line")
    done < "$file"

    printf '%s\n' "${entries[@]}"
}

# Select packages interactively
# Returns selected entries (full lines: type|name|description)
select_packages() {
    local category="$1"
    local file="$2"

    [[ ! -f "$file" ]] && return 0

    local entries=()
    while IFS= read -r line; do
        entries+=("$line")
    done < <(parse_package_file "$file")

    [[ ${#entries[@]} -eq 0 ]] && return 0

    if $HAS_GUM; then
        # Build display labels: "name - description"
        local labels=()
        for entry in "${entries[@]}"; do
            local name desc
            IFS='|' read -r _ name desc <<< "$entry"
            name="$(echo "$name" | xargs)"
            desc="$(echo "$desc" | xargs)"
            labels+=("$name - $desc")
        done

        # All selected by default
        local gum_args=(--no-limit --header "Select $category packages:")
        for label in "${labels[@]}"; do
            gum_args+=(--selected "$label")
        done

        local selected
        selected="$(printf '%s\n' "${labels[@]}" | gum choose "${gum_args[@]}")" || return 0

        # Map selected labels back to full entries
        while IFS= read -r sel_label; do
            [[ -z "$sel_label" ]] && continue
            local sel_name="${sel_label%% - *}"
            for entry in "${entries[@]}"; do
                local entry_name
                IFS='|' read -r _ entry_name _ <<< "$entry"
                entry_name="$(echo "$entry_name" | xargs)"
                if [[ "$entry_name" == "$sel_name" ]]; then
                    echo "$entry"
                    break
                fi
            done
        done <<< "$selected"
    else
        # Bash fallback: show numbered list, select all by default
        echo ""
        echo "  ── $category ──"
        local i=1
        for entry in "${entries[@]}"; do
            local name desc
            IFS='|' read -r _ name desc <<< "$entry"
            name="$(echo "$name" | xargs)"
            desc="$(echo "$desc" | xargs)"
            echo "    $i) $name - $desc"
            ((i++))
        done
        echo ""
        read -rp "  Enter numbers to install (comma-separated, Enter=all): " selection

        if [[ -z "$selection" ]]; then
            # Select all
            printf '%s\n' "${entries[@]}"
        else
            IFS=',' read -ra nums <<< "$selection"
            for num in "${nums[@]}"; do
                num="$(echo "$num" | xargs)"
                if [[ "$num" =~ ^[0-9]+$ ]] && (( num >= 1 && num <= ${#entries[@]} )); then
                    echo "${entries[$((num-1))]}"
                fi
            done
        fi
    fi
}

# ─── Config Selection ────────────────────────────────────────

# Select configs to deploy from manifest
# Manifest format: display_name|source|dest|mode|description
# Returns selected manifest lines
select_configs() {
    local manifest_entries=("$@")

    [[ ${#manifest_entries[@]} -eq 0 ]] && return 0

    if $HAS_GUM; then
        local labels=()
        for entry in "${manifest_entries[@]}"; do
            local display_name _src _dst _mode description
            IFS='|' read -r display_name _src _dst _mode description <<< "$entry"
            if [[ -n "$description" ]]; then
                labels+=("$display_name — $description")
            else
                labels+=("$display_name")
            fi
        done

        local gum_args=(--no-limit --header "Select configs to deploy:")
        for label in "${labels[@]}"; do
            gum_args+=(--selected "$label")
        done

        local selected
        selected="$(printf '%s\n' "${labels[@]}" | gum choose "${gum_args[@]}")" || return 0

        while IFS= read -r sel_label; do
            [[ -z "$sel_label" ]] && continue
            local sel_name="${sel_label%% — *}"
            for entry in "${manifest_entries[@]}"; do
                local display_name
                IFS='|' read -r display_name _ _ _ _ <<< "$entry"
                if [[ "$display_name" == "$sel_name" ]]; then
                    echo "$entry"
                    break
                fi
            done
        done <<< "$selected"
    else
        echo ""
        echo "  ── Config Files ──"
        local i=1
        for entry in "${manifest_entries[@]}"; do
            local display_name source dest mode description
            IFS='|' read -r display_name source dest mode description <<< "$entry"
            if [[ -n "$description" ]]; then
                echo "    $i) $display_name ($mode → $dest)"
                echo "       $description"
            else
                echo "    $i) $display_name ($mode → $dest)"
            fi
            ((i++))
        done
        echo ""
        read -rp "  Enter numbers to deploy (comma-separated, Enter=all): " selection

        if [[ -z "$selection" ]]; then
            printf '%s\n' "${manifest_entries[@]}"
        else
            IFS=',' read -ra nums <<< "$selection"
            for num in "${nums[@]}"; do
                num="$(echo "$num" | xargs)"
                if [[ "$num" =~ ^[0-9]+$ ]] && (( num >= 1 && num <= ${#manifest_entries[@]} )); then
                    echo "${manifest_entries[$((num-1))]}"
                fi
            done
        fi
    fi
}

# ─── Claude Fragment Selection ────────────────────────────────

select_claude_fragments() {
    local fragments_dir="$1"
    local fragments=()
    local -A descriptions

    # Load descriptions from descriptions.txt
    local desc_file="$fragments_dir/descriptions.txt"
    if [[ -f "$desc_file" ]]; then
        while IFS='|' read -r fname fdesc || [[ -n "$fname" ]]; do
            [[ -z "$fname" || "$fname" == \#* ]] && continue
            fname="$(echo "$fname" | xargs)"
            descriptions["$fname"]="$(echo "$fdesc" | xargs)"
        done < "$desc_file"
    fi

    for f in "$fragments_dir"/*.json; do
        [[ -f "$f" ]] || continue
        fragments+=("$(basename "$f")")
    done

    [[ ${#fragments[@]} -eq 0 ]] && return 0

    if $HAS_GUM; then
        local labels=()
        for frag in "${fragments[@]}"; do
            local desc="${descriptions[$frag]:-}"
            if [[ -n "$desc" ]]; then
                labels+=("$frag — $desc")
            else
                labels+=("$frag")
            fi
        done

        local gum_args=(--no-limit --header "Select Claude Code settings fragments:")
        for label in "${labels[@]}"; do
            gum_args+=(--selected "$label")
        done

        local selected
        selected="$(printf '%s\n' "${labels[@]}" | gum choose "${gum_args[@]}")" || return 0

        # Extract filename from "filename — description" format
        while IFS= read -r sel_label; do
            [[ -z "$sel_label" ]] && continue
            echo "${sel_label%% — *}"
        done <<< "$selected"
    else
        echo ""
        echo "  ── Claude Code Fragments ──"
        local i=1
        for frag in "${fragments[@]}"; do
            local desc="${descriptions[$frag]:-}"
            if [[ -n "$desc" ]]; then
                echo "    $i) $frag"
                echo "       $desc"
            else
                echo "    $i) $frag"
            fi
            ((i++))
        done
        echo ""
        read -rp "  Enter numbers (comma-separated, Enter=all): " selection

        if [[ -z "$selection" ]]; then
            printf '%s\n' "${fragments[@]}"
        else
            IFS=',' read -ra nums <<< "$selection"
            for num in "${nums[@]}"; do
                num="$(echo "$num" | xargs)"
                if [[ "$num" =~ ^[0-9]+$ ]] && (( num >= 1 && num <= ${#fragments[@]} )); then
                    echo "${fragments[$((num-1))]}"
                fi
            done
        fi
    fi
}
