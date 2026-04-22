#!/usr/bin/env bash
# APEX Skills Installer v2.0
# Usage: curl -fsSL https://raw.githubusercontent.com/Nadav011/apex-skills/main/install.sh | bash
# Or:    bash install.sh [--platform claude-code|gemini|kiro|cursor]
set -euo pipefail

REPO="https://github.com/Nadav011/apex-skills.git"
RAW="https://raw.githubusercontent.com/Nadav011/apex-skills/main"

# ── Platform detection ───────────────────────────────────────────────
detect_platform() {
    local p="${1:-}"
    if [ -n "$p" ]; then echo "$p"; return; fi
    if   [ -d "$HOME/.claude" ];  then echo "claude-code"
    elif [ -d "$HOME/.gemini" ];  then echo "gemini"
    elif [ -d "$HOME/.kiro" ];    then echo "kiro"
    elif [ -d "$HOME/.codex" ];   then echo "codex"
    else echo "claude-code"
    fi
}

target_dir() {
    case "$1" in
        claude-code) echo "$HOME/.claude/skills" ;;
        gemini)      echo "$HOME/.gemini/skills" ;;
        kiro)        echo "$HOME/.kiro/agents" ;;
        codex)       echo "$HOME/.codex/skills" ;;
        cursor)      echo "$(pwd)/.cursor/rules" ;;
        *)           echo "$HOME/.claude/skills" ;;
    esac
}

PLATFORM=$(detect_platform "${1:-}")
DEST=$(target_dir "$PLATFORM")
SOURCE_CACHE="$HOME/.apex-skills-cache"

printf "\n╔══════════════════════════════════════════╗\n"
printf "║         APEX Skills Installer v2         ║\n"
printf "║   22 battle-tested skills → you          ║\n"
printf "╚══════════════════════════════════════════╝\n\n"
printf "Platform : %s\n" "$PLATFORM"
printf "Target   : %s\n\n" "$DEST"

# ── Download ─────────────────────────────────────────────────────────
mkdir -p "$DEST"

if command -v git &>/dev/null; then
    if [ -d "$SOURCE_CACHE/.git" ]; then
        printf "Updating cache...\n"
        git -C "$SOURCE_CACHE" pull --quiet --ff-only 2>/dev/null || true
    else
        printf "Cloning apex-skills...\n"
        git clone --depth=1 --quiet "$REPO" "$SOURCE_CACHE"
    fi
    SKILLS_DIR="$SOURCE_CACHE/skills"
else
    printf "git not found — please install git and retry\n" >&2
    exit 1
fi

# ── Install ──────────────────────────────────────────────────────────
INSTALLED=0
UPDATED=0

for skill_dir in "$SKILLS_DIR"/*/; do
    [ -d "$skill_dir" ] || continue
    name=$(basename "$skill_dir")
    skill_file="$skill_dir/SKILL.md"
    [ -f "$skill_file" ] || continue

    target="$DEST/$name"
    mkdir -p "$target"

    if [ -f "$target/SKILL.md" ] && cmp -s "$skill_file" "$target/SKILL.md"; then
        :  # unchanged
    elif [ -f "$target/SKILL.md" ]; then
        cp "$skill_file" "$target/SKILL.md"
        printf "  ↑ %-28s (updated)\n" "$name"
        UPDATED=$((UPDATED + 1))
    else
        cp "$skill_file" "$target/SKILL.md"
        printf "  + %-28s\n" "$name"
        INSTALLED=$((INSTALLED + 1))
    fi
done

TOTAL=$((INSTALLED + UPDATED))

printf "\n✅ Done — %d new, %d updated (%d total skills)\n\n" \
    "$INSTALLED" "$UPDATED" "$TOTAL"

printf "Restart Claude Code / your AI assistant to activate.\n"
printf "\nQuick test:\n"
printf "  Ask: 'Review this file for RTL safety'\n"
printf "  Expect: rtl-validator flags any ml- / mr- / text-left classes\n\n"
