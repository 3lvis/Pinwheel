#!/usr/bin/env bash
# PreToolUse gate for Pinwheel: editing capture/plugin source is where bug fixes land, and red-first TDD
# is mandatory there. Inject a reminder at the moment of the edit so momentum can't skip the failing test.
# Fail-safe: always exit 0 (never blocks); if anything goes wrong it just stays silent.
input="$(cat)"
file="$(printf '%s' "$input" | python3 -c 'import json,sys
try:
    print((json.load(sys.stdin).get("tool_input") or {}).get("file_path",""))
except Exception:
    print("")' 2>/dev/null)"
case "$file" in
  *Pinwheel/Sources/Pinwheel/Capture/*|*figma-plugin/code.ts)
    printf '%s' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"RED-FIRST GATE (bug fixes): you are editing capture/plugin source. If this is a bug fix or behavior change, the immediately preceding step must be a test you watched go RED for the right reason. If you have not shown red yet: revert this edit, write/adjust the failing test, run it red, THEN fix. Post-red fix edits and demo-content edits are fine."}}'
    ;;
esac
exit 0
