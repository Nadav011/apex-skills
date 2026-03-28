#!/usr/bin/env bash
# APEX Skills Installer — one command setup
set -euo pipefail

echo "Installing APEX Skills..."

DEST="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
mkdir -p "$DEST"

# Clone or update
if [ -d "$DEST/.apex-skills-source" ]; then
    cd "$DEST/.apex-skills-source" && git pull --quiet
else
    git clone --quiet https://github.com/Nadav011/apex-skills.git "$DEST/.apex-skills-source"
fi

# Copy skills
for skill_dir in "$DEST/.apex-skills-source/skills"/*/; do
    name=$(basename "$skill_dir")
    [ -f "$skill_dir/SKILL.md" ] || continue
    mkdir -p "$DEST/$name"
    cp "$skill_dir/SKILL.md" "$DEST/$name/"
done

INSTALLED=$(find "$DEST/.apex-skills-source/skills" -name "SKILL.md" | wc -l)
echo "✅ Installed $INSTALLED APEX skills to $DEST"
echo ""
echo "Skills: rtl-validator, rtl-fix, testing-rules, security-rules, frontend-rules,"
echo "        backend-rules, adversarial-review, edge-case-hunter, apex-guards, a11y,"
echo "        pwa-expert, perf-expert, flutter-rules, zod-patterns, owasp-security"
echo ""
echo "Usage: /rtl-validator, /adversarial-review, /testing-rules, etc."
