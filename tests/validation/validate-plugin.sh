#!/usr/bin/env bash
# Validates the roninforge-sveltekit plugin structure and content.
# Run from the repository root: ./tests/validation/validate-plugin.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ERRORS=0
WARNINGS=0

red()    { printf "\033[31m%s\033[0m\n" "$1"; }
green()  { printf "\033[32m%s\033[0m\n" "$1"; }
yellow() { printf "\033[33m%s\033[0m\n" "$1"; }

error() { red "ERROR: $1"; ERRORS=$((ERRORS + 1)); }
warn()  { yellow "WARN:  $1"; WARNINGS=$((WARNINGS + 1)); }
pass()  { green "PASS:  $1"; }

echo "=== Plugin Structure Validation ==="
echo ""

# 1. plugin.json exists and is valid JSON
PLUGIN_JSON="$REPO_ROOT/.cursor-plugin/plugin.json"
if [ -f "$PLUGIN_JSON" ]; then
    if command -v jq >/dev/null 2>&1; then
        if jq empty "$PLUGIN_JSON" >/dev/null 2>&1; then
            pass "plugin.json is valid JSON (jq)"
            for field in name version description author license; do
                if [ "$(jq -r "has(\"$field\")" "$PLUGIN_JSON")" = "true" ]; then
                    pass "plugin.json has '$field' field"
                else
                    warn "plugin.json missing recommended '$field' field"
                fi
            done
            NAME_VAL=$(jq -r '.name' "$PLUGIN_JSON")
            if [ "$NAME_VAL" = "roninforge-sveltekit" ]; then
                pass "plugin.json name is roninforge-sveltekit"
            else
                error "plugin.json name is '$NAME_VAL', expected 'roninforge-sveltekit'"
            fi
        else
            error "plugin.json is not valid JSON"
        fi
    elif command -v python3 >/dev/null 2>&1; then
        if python3 -c "import json; json.load(open('$PLUGIN_JSON'))" 2>/dev/null; then
            pass "plugin.json is valid JSON (python3 fallback)"
        else
            error "plugin.json is not valid JSON"
        fi
    else
        warn "Neither jq nor python3 available; skipping JSON validation"
    fi
else
    error ".cursor-plugin/plugin.json not found"
fi

echo ""
echo "=== Rule Files ==="
echo ""

# 2. Rule files: must have YAML frontmatter with description, globs, alwaysApply
RULE_COUNT=0
for rule_file in "$REPO_ROOT"/rules/*.mdc; do
    [ -f "$rule_file" ] || continue
    RULE_COUNT=$((RULE_COUNT + 1))
    fname=$(basename "$rule_file")

    first_line=$(head -1 "$rule_file")
    if [ "$first_line" = "---" ]; then
        pass "$fname has YAML frontmatter"

        if grep -qE "^description:" "$rule_file"; then
            pass "$fname has description"
        else
            error "$fname missing 'description' in frontmatter"
        fi

        if grep -qE "^alwaysApply:" "$rule_file"; then
            pass "$fname has alwaysApply"
        else
            error "$fname missing 'alwaysApply' in frontmatter"
        fi

        # Either globs (scoped rule) OR alwaysApply: true (always-on rule).
        if grep -qE "^globs:" "$rule_file" || grep -qE "^alwaysApply:[[:space:]]*true" "$rule_file"; then
            pass "$fname has scope (globs or alwaysApply: true)"
        else
            warn "$fname has neither globs nor alwaysApply: true (may never fire)"
        fi
    else
        error "$fname missing YAML frontmatter (must start with ---)"
    fi

    LINES=$(wc -l < "$rule_file" | tr -d ' ')
    # sveltekit-anti-patterns is intentionally long; 40 numbered entries with BAD/GOOD pairs.
    if [ "$LINES" -lt 1000 ]; then
        pass "$fname is $LINES lines (under 1000)"
    else
        warn "$fname is $LINES lines (consider splitting)"
    fi
done

if [ "$RULE_COUNT" -ge 10 ]; then
    pass "Found $RULE_COUNT rule files (target 10+)"
else
    warn "Found $RULE_COUNT rule files (target 10+)"
fi

echo ""
echo "=== Skill Files ==="
echo ""

SKILL_COUNT=0
for skill_dir in "$REPO_ROOT"/skills/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name=$(basename "$skill_dir")

    if [ -f "$skill_dir/SKILL.md" ]; then
        SKILL_COUNT=$((SKILL_COUNT + 1))
        pass "Skill '$skill_name' has SKILL.md"

        first_line=$(head -1 "$skill_dir/SKILL.md")
        if [ "$first_line" = "---" ]; then
            pass "Skill '$skill_name' has YAML frontmatter"

            if grep -qE "^name:" "$skill_dir/SKILL.md"; then
                SKILL_NAME_VALUE=$(grep "^name:" "$skill_dir/SKILL.md" | head -1 | sed 's/name: *//' | tr -d '"')
                if [ "$SKILL_NAME_VALUE" = "$skill_name" ]; then
                    pass "Skill '$skill_name' name matches directory"
                else
                    error "Skill name '$SKILL_NAME_VALUE' does not match directory '$skill_name'"
                fi
            else
                error "Skill '$skill_name' missing 'name' in frontmatter"
            fi

            if grep -qE "^description:" "$skill_dir/SKILL.md"; then
                pass "Skill '$skill_name' has description"
            else
                error "Skill '$skill_name' missing 'description' in frontmatter"
            fi
        else
            error "Skill '$skill_name' SKILL.md missing YAML frontmatter"
        fi
    else
        error "Skill directory '$skill_name' missing SKILL.md"
    fi
done

if [ "$SKILL_COUNT" -ge 5 ]; then
    pass "Found $SKILL_COUNT skills (target 5+)"
else
    warn "Found $SKILL_COUNT skills (target 5+)"
fi

echo ""
echo "=== Agent Files ==="
echo ""

AGENT_COUNT=0
for agent_file in "$REPO_ROOT"/agents/*.md; do
    [ -f "$agent_file" ] || continue
    AGENT_COUNT=$((AGENT_COUNT + 1))
    fname=$(basename "$agent_file")

    first_line=$(head -1 "$agent_file")
    if [ "$first_line" = "---" ]; then
        pass "Agent '$fname' has YAML frontmatter"
        grep -qE "^name:" "$agent_file" && pass "Agent '$fname' has name" || error "Agent '$fname' missing 'name'"
        grep -qE "^description:" "$agent_file" && pass "Agent '$fname' has description" || warn "Agent '$fname' missing description"
    else
        error "Agent '$fname' missing YAML frontmatter"
    fi
done

[ "$AGENT_COUNT" -ge 1 ] && pass "Found $AGENT_COUNT agent file(s)" || warn "No agent files found"

echo ""
echo "=== Required Files ==="
echo ""

for req_file in README.md LICENSE CHANGELOG.md; do
    if [ -f "$REPO_ROOT/$req_file" ]; then
        pass "$req_file exists"
    else
        error "$req_file not found"
    fi
done

echo ""
echo "=== Em dash / emoji audit ==="
echo ""

# U+2014 EM DASH; never allowed.
EMDASH_HITS=$(grep -rln $'\xe2\x80\x94' "$REPO_ROOT/rules" "$REPO_ROOT/skills" "$REPO_ROOT/agents" "$REPO_ROOT/README.md" "$REPO_ROOT/CHANGELOG.md" 2>/dev/null || true)
if [ -z "$EMDASH_HITS" ]; then
    pass "No em dashes (U+2014) in rules / skills / agents / README / CHANGELOG"
else
    error "Em dash (U+2014) found in:"
    echo "$EMDASH_HITS"
fi

# Any emoji presence (broad: anything in the common emoji ranges).
EMOJI_HITS=$(grep -rlnP '[\x{1F300}-\x{1FAFF}\x{2600}-\x{27BF}\x{1F000}-\x{1F9FF}]' "$REPO_ROOT/rules" "$REPO_ROOT/skills" "$REPO_ROOT/agents" "$REPO_ROOT/README.md" "$REPO_ROOT/CHANGELOG.md" 2>/dev/null || true)
if [ -z "$EMOJI_HITS" ]; then
    pass "No emojis in rules / skills / agents / README / CHANGELOG"
else
    error "Emoji found in:"
    echo "$EMOJI_HITS"
fi

echo ""
echo "=== Fixture Audit ==="
echo ""

CORRECT_DIR="$REPO_ROOT/tests/fixtures/correct-sample"
ANTI_DIR="$REPO_ROOT/tests/fixtures/anti-pattern-sample"

# correct-sample MUST NOT contain banned SvelteKit 1 / Svelte 4 patterns
if [ -d "$CORRECT_DIR" ]; then
    pass "correct-sample fixture directory exists"

    # Banned patterns:
    # - on:click and any on:event
    # - $: reactive statement (line begins with optional whitespace + $: + non-=)
    # - export let
    # - <slot ...>
    # - createEventDispatcher import
    # - throw redirect / throw error
    # - cookies.set / cookies.delete without path
    # - $app/stores import (use $app/state)
    # - lucide-svelte (use @lucide/svelte)
    # - new App({ target ... })
    ON_DIRECTIVE=$(grep -rEn --include='*.svelte' 'on:[a-z]+=' "$CORRECT_DIR" 2>/dev/null | head -3 || true)
    REACTIVE_DOLLAR=$(grep -rEn --include='*.svelte' '^[[:space:]]*\$:[^=]' "$CORRECT_DIR" 2>/dev/null | head -3 || true)
    EXPORT_LET=$(grep -rEn --include='*.svelte' '^[[:space:]]*export[[:space:]]+let[[:space:]]' "$CORRECT_DIR" 2>/dev/null | head -3 || true)
    SLOT_TAG=$(grep -rEn --include='*.svelte' '<slot([[:space:]]|/|>|$)' "$CORRECT_DIR" 2>/dev/null | head -3 || true)
    DISPATCHER=$(grep -rEn --include='*.svelte' --include='*.ts' --include='*.js' 'createEventDispatcher' "$CORRECT_DIR" 2>/dev/null | head -3 || true)
    THROW_KIT=$(grep -rEn --include='*.ts' --include='*.js' --include='*.svelte' 'throw[[:space:]]+(redirect|error)\(' "$CORRECT_DIR" 2>/dev/null | head -3 || true)
    # Cookies without path: scan each cookies.set/delete call across its argument list.
    # We use python (always available on macOS / modern Linux) to read each file and
    # check whether the matched call's parenthesised arguments mention `path`.
    COOKIES_NO_PATH=""
    if command -v python3 >/dev/null 2>&1; then
        COOKIES_NO_PATH=$(python3 - "$CORRECT_DIR" <<'PYEOF' || true
import os, re, sys
root = sys.argv[1]
pat = re.compile(r'cookies\.(set|delete)\s*\(')
hits = []
for dirpath, _, filenames in os.walk(root):
    for fname in filenames:
        if not fname.endswith(('.ts', '.js', '.svelte')):
            continue
        path = os.path.join(dirpath, fname)
        try:
            text = open(path, encoding='utf-8').read()
        except Exception:
            continue
        for m in pat.finditer(text):
            # Walk forward, balance parens, then check that arg block.
            i = m.end()
            depth = 1
            while i < len(text) and depth > 0:
                ch = text[i]
                if ch == '(':
                    depth += 1
                elif ch == ')':
                    depth -= 1
                i += 1
            block = text[m.end():i-1]
            if 'path' not in block:
                line = text[:m.start()].count('\n') + 1
                hits.append(f"{path}:{line}:cookies.{m.group(1)}( ... ) without path")
                if len(hits) >= 3:
                    break
        if len(hits) >= 3:
            break
    if len(hits) >= 3:
        break
print('\n'.join(hits))
PYEOF
)
    fi
    APP_STORES=$(grep -rEn --include='*.svelte' --include='*.ts' --include='*.js' "from ['\"]\$app/stores['\"]" "$CORRECT_DIR" 2>/dev/null | head -3 || true)
    LUCIDE_OLD=$(grep -rEn --include='*.svelte' --include='*.ts' --include='*.js' "from ['\"]lucide-svelte['\"]" "$CORRECT_DIR" 2>/dev/null | head -3 || true)
    NEW_APP=$(grep -rEn --include='*.ts' --include='*.js' 'new App\(\{' "$CORRECT_DIR" 2>/dev/null | head -3 || true)

    CORRECT_VIOLATIONS=0
    [ -n "$ON_DIRECTIVE" ]   && { error "correct-sample uses on:event directive (anti-pattern #4):"; echo "$ON_DIRECTIVE"; CORRECT_VIOLATIONS=$((CORRECT_VIOLATIONS+1)); }
    [ -n "$REACTIVE_DOLLAR" ] && { error "correct-sample uses \$: reactive statement (anti-pattern #2):"; echo "$REACTIVE_DOLLAR"; CORRECT_VIOLATIONS=$((CORRECT_VIOLATIONS+1)); }
    [ -n "$EXPORT_LET" ]     && { error "correct-sample uses 'export let' (anti-pattern #3):"; echo "$EXPORT_LET"; CORRECT_VIOLATIONS=$((CORRECT_VIOLATIONS+1)); }
    [ -n "$SLOT_TAG" ]       && { error "correct-sample uses <slot> (anti-pattern #7):"; echo "$SLOT_TAG"; CORRECT_VIOLATIONS=$((CORRECT_VIOLATIONS+1)); }
    [ -n "$DISPATCHER" ]     && { error "correct-sample uses createEventDispatcher (anti-pattern #6):"; echo "$DISPATCHER"; CORRECT_VIOLATIONS=$((CORRECT_VIOLATIONS+1)); }
    [ -n "$THROW_KIT" ]      && { error "correct-sample uses 'throw error(' / 'throw redirect(' (anti-pattern #17):"; echo "$THROW_KIT"; CORRECT_VIOLATIONS=$((CORRECT_VIOLATIONS+1)); }
    [ -n "$COOKIES_NO_PATH" ] && { error "correct-sample calls cookies.set/delete without path (anti-pattern #19):"; echo "$COOKIES_NO_PATH"; CORRECT_VIOLATIONS=$((CORRECT_VIOLATIONS+1)); }
    [ -n "$APP_STORES" ]     && { error "correct-sample imports from \$app/stores (anti-pattern #22):"; echo "$APP_STORES"; CORRECT_VIOLATIONS=$((CORRECT_VIOLATIONS+1)); }
    [ -n "$LUCIDE_OLD" ]     && { error "correct-sample imports from lucide-svelte (anti-pattern #30):"; echo "$LUCIDE_OLD"; CORRECT_VIOLATIONS=$((CORRECT_VIOLATIONS+1)); }
    [ -n "$NEW_APP" ]        && { error "correct-sample uses 'new App({' (anti-pattern #8):"; echo "$NEW_APP"; CORRECT_VIOLATIONS=$((CORRECT_VIOLATIONS+1)); }

    [ "$CORRECT_VIOLATIONS" -eq 0 ] && pass "correct-sample fixture is free of banned Svelte 4 / SvelteKit 1 patterns"

    # Pinned versions in correct-sample/package.json
    if [ -f "$CORRECT_DIR/package.json" ] && command -v jq >/dev/null 2>&1; then
        SVELTE_VER=$(jq -r '.dependencies.svelte // ""' "$CORRECT_DIR/package.json")
        KIT_VER=$(jq -r '.devDependencies."@sveltejs/kit" // .dependencies."@sveltejs/kit" // ""' "$CORRECT_DIR/package.json")
        case "$SVELTE_VER" in
            ^5.*) pass "correct-sample pins svelte $SVELTE_VER" ;;
            *) error "correct-sample svelte pin '$SVELTE_VER' is not ^5.x" ;;
        esac
        case "$KIT_VER" in
            ^2.*) pass "correct-sample pins @sveltejs/kit $KIT_VER" ;;
            *) error "correct-sample @sveltejs/kit pin '$KIT_VER' is not ^2.x" ;;
        esac
    fi
else
    warn "correct-sample fixture directory not found"
fi

# anti-pattern-sample MUST contain at least 8 tracked violations
if [ -d "$ANTI_DIR" ]; then
    pass "anti-pattern-sample fixture directory exists"

    TOTAL_ANTI=0

    # Each grep -c counts matching lines per file; awk sums.
    ANTI_HITS=$(grep -rEc 'on:[a-z]+=|^[[:space:]]*\$:[^=]|^[[:space:]]*export[[:space:]]+let[[:space:]]|<slot([[:space:]]|/|>|$)|createEventDispatcher|throw[[:space:]]+(redirect|error)\(|from .\$app/stores.|from .lucide-svelte.|new App\(\{|writable\(' "$ANTI_DIR" 2>/dev/null | awk -F: '{s+=$2} END {print s+0}')
    TOTAL_ANTI=$((TOTAL_ANTI + ANTI_HITS))

    # cookies.set / cookies.delete without path: count lines that match the call without "path"
    COOKIES_NOPATH_HITS=$(grep -rEn 'cookies\.(set|delete)\(' "$ANTI_DIR" 2>/dev/null | grep -vc "path" || true)
    TOTAL_ANTI=$((TOTAL_ANTI + COOKIES_NOPATH_HITS))

    if [ "$TOTAL_ANTI" -ge 8 ]; then
        pass "anti-pattern-sample contains $TOTAL_ANTI tracked violations (target 8+)"
    else
        warn "anti-pattern-sample has only $TOTAL_ANTI tracked violations (target 8+)"
    fi
else
    warn "anti-pattern-sample fixture directory not found"
fi

echo ""
echo "=== Hanko (optional) ==="
echo ""

if command -v hanko >/dev/null 2>&1; then
    # Hanko validates Claude Code plugin manifests (.claude-plugin/plugin.json).
    # This repo is a Cursor plugin (.cursor-plugin/plugin.json), so hanko does
    # not apply. Skip with an info note rather than failing.
    if [ -f "$REPO_ROOT/.claude-plugin/plugin.json" ] || [ -f "$REPO_ROOT/.claude-plugin/marketplace.json" ]; then
        HANKO_SUB="validate"
        hanko --help 2>&1 | grep -qE '\bcheck\b' && HANKO_SUB="check"
        HANKO_OUT=$(hanko "$HANKO_SUB" "$REPO_ROOT" 2>&1) \
            && pass "hanko $HANKO_SUB passed" \
            || { error "hanko $HANKO_SUB failed"; echo "$HANKO_OUT"; }
    else
        green "INFO:  hanko installed but this is a Cursor plugin (.cursor-plugin/) - hanko targets Claude Code plugins (.claude-plugin/). Skipping."
    fi
else
    warn "hanko not installed; skipping plugin manifest validation. Install: https://github.com/RoninForge/hanko"
fi

echo ""
echo "=== Summary ==="
echo ""
echo "Errors:   $ERRORS"
echo "Warnings: $WARNINGS"
echo ""

if [ "$ERRORS" -gt 0 ]; then
    red "FAILED - fix $ERRORS error(s) before submission"
    exit 1
elif [ "$WARNINGS" -gt 0 ]; then
    yellow "PASSED with $WARNINGS warning(s)"
    exit 0
else
    green "ALL CHECKS PASSED"
    exit 0
fi
