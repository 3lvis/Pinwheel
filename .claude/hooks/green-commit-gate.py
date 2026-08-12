#!/usr/bin/env python3
# PreToolUse gate (Bash): block landing code on `main` unless the commit(s) being merged CLAIM tests ran
# green (a `Tests: ... green` trailer). GitHub Actions CI is paused (runner-only flake + scarce minutes),
# so per AGENTS.md -> "Local green-commit gate" the commit's claim is the merge signal. This hook does not
# run the tests (too slow for a hook); it enforces the claim is present so the convention can't be skipped.
# Fail-open on any error; deny (exit 2) only when the claim is confirmed absent.
import json, re, subprocess, sys


def run(args, timeout=15):
    try:
        return subprocess.run(args, capture_output=True, text=True, timeout=timeout).stdout
    except Exception:
        return ""


def has_green_claim(message):
    return bool(re.search(r"(?is)tests?:.{0,100}\bgreen\b", message)
                or re.search(r"(?is)\bgreen\b.{0,40}xcodebuild", message))


def main():
    try:
        command = (json.load(sys.stdin).get("tool_input") or {}).get("command", "") or ""
    except Exception:
        sys.exit(0)

    # Only treat a merge invocation that STARTS a command segment as a real merge — so a mention inside a
    # quoted argument (an echo, a grep, a test payload) doesn't false-trigger the gate.
    segments = [segment.strip() for segment in re.split(r"[;\n]|&&|\|\|?", command)]
    is_pr_merge = any(re.match(r"gh\s+pr\s+merge\b", segment) for segment in segments)
    is_git_merge = any(re.match(r"git\s+merge\b", segment) for segment in segments) \
        and re.search(r"--(abort|continue|quit)", command) is None
    if not (is_pr_merge or is_git_merge):
        sys.exit(0)

    # `git merge` only lands on main when main is checked out; merging main INTO a feature branch is fine.
    if is_git_merge and not is_pr_merge:
        if run(["git", "rev-parse", "--abbrev-ref", "HEAD"]).strip() != "main":
            sys.exit(0)

    # Check the tip commit being merged. `git merge <ref>` on main lands <ref>'s tip; otherwise (the
    # common `gh pr merge` flow, run from the branch just committed + pushed) the local HEAD is that tip.
    message = ""
    if is_git_merge and not is_pr_merge:
        ref = re.search(r"git\s+merge\s+(?:--\S+\s+)*(\S+)", command)
        if ref:
            message = run(["git", "log", "-1", "--format=%B", ref.group(1)])
    if not message.strip():
        message = run(["git", "log", "-1", "--format=%B"])  # HEAD
    if not message.strip():
        sys.exit(0)  # can't determine the tip -> fail open

    if has_green_claim(message):
        sys.exit(0)

    sys.stderr.write(
        "GREEN-COMMIT GATE (blocked): the commit landing on main does not claim tests ran green. "
        "GitHub Actions CI is paused, so a merge is gated on the commit stating local results "
        "(AGENTS.md -> 'Local green-commit gate'). Run both tiers with xcodebuild -- unit: "
        "-scheme PinwheelTests; UI: -scheme Demo -only-testing:DemoUITests -retry-tests-on-failure "
        "-test-iterations 3 -- then add a 'Tests: unit NN/NN + UI green (local xcodebuild)' trailer to "
        "the tip commit (amend it or add a commit) and re-run the merge.\n"
    )
    sys.exit(2)


main()
