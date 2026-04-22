---
name: north-bug-fix
description: Implement and validate North bug fixes from an existing `.triage-artifacts-{issue_id}/REPORT.md` triage report. Use when a North bug already has a triage report and you need to rank likely fixes, try them from highest-confidence to lowest, validate each attempt with local checks plus a headed Playwright browser and video, and stop on first verified success or after all ranked attempts fail. If `REPORT.md` is missing, tell the user to run `north-bug-triage` first.
---

# North Bug Fix

## Purpose

Turn a strong triage handoff into either a verified fix with browser evidence, or an honest failed-attempt report.

**Precondition**: `.triage-artifacts-{issue_id}/REPORT.md` must exist. If it does not, stop and tell the user to run `north-bug-triage` first.

Playwright validation is required because the goal is to restore user-visible behavior, not only to make tests pass. Browser work is delegated to the `north-ui-driver` skill.

## Default order

Adapt based on context; skip steps the user already completed.

0. **Confirm the handoff** — read `REPORT.md` fully; extract expected behavior, repro URL, strongest observables, likely failing boundary, hypotheses, long-term fixes, and verification plan. If the report does not clearly say what success looks like, stop and ask before changing code.
1. **Rank** candidate fixes from most to least recommended (see heuristics below).
2. **Isolate** attempts safely. For multi-candidate runs or when the repo has unrelated uncommitted changes, use the `best-of-n-runner` subagent — it already runs each attempt in its own git worktree. Never revert or overwrite unrelated user changes.
3. **Implement** the highest-ranked candidate. State the hypothesis, the behavior change, and the smallest evidence that would prove success *before* editing.
4. **Validate locally** — smallest useful focused test, typecheck, or endpoint-level check.
5. **Validate in a headed browser** — use the `north-ui-driver` skill to re-run the exact flow from the triage report. Capture video, console, network. A fix only counts as passed when the expected behavior happens, the previous symptom is gone, *and* the originally-implicated network/API/async failure also goes clean.
6. **On failure**, record why, discard only your own changes, and start the next attempt fresh. If browser state may have masked the result, start the next attempt with a fresh Playwright session/profile.
7. **Stop** on the first verified success or after all ranked candidates fail.
8. **Write** the final report to `.triage-artifacts-{issue_id}/fix/FIX_REPORT.md` using [references/fix-report-template.md](references/fix-report-template.md).

## Configuration

Defaults and paths: [config.json](config.json). Key settings:

- Input: `.triage-artifacts-{issue_id}/REPORT.md`
- Fix folder: `.triage-artifacts-{issue_id}/fix`
- Fix report: `.triage-artifacts-{issue_id}/fix/FIX_REPORT.md`
- Playwright validation is part of success — UI-only test passes are not enough.

## North-specific ranking heuristics

These are the fix-skill's unique insight. Apply them after sourcing candidates from `REPORT.md`'s *Likely Failing Boundary*, *Hypotheses*, *Long-Term Fixes*, and *Verification Plan* sections.

- **If the failure starts after kickoff**, rank async or back-compat fixes above frontend polling, retry, or toast changes. The symptom is downstream of the UI.
- **If the strongest observables are network or API failures**, keep UI-only fixes low-ranked unless they also remove the failing request. Suppressing an error banner is not a fix.
- **If the likely boundary is auth or permissions propagation**, rank boundary fixes above retries or optimistic UI. Retries mask permission bugs until they don't.
- **If the report names a specific service chain**, start inside that chain before broader fallback behavior. Widening scope first wastes attempts.
- Tie-break by smallest blast radius, highest reversibility, and closest evidence match.

## Gotchas (false positives)

- **Green toast, happy empty state, or optimistic success indicator can be a false positive.** If triage implicated `inngest-server`, `toolkit-backend`, or `toolkit-task-runner`, require the underlying request or execution evidence to go clean too — not only the UI.
- **Triage repro URLs go stale.** Confirm the route, flags, and redirects still match the original repro before concluding the bug disappeared.
- **Reusing a persistent Playwright profile can hide the bug** by preserving auth, cached feature flags, or completed setup. If behavior changes unexpectedly between attempts, start fresh. `north-ui-driver`'s gotchas cover the delete-profile recovery.
- **A frontend-only change that suppresses an error banner is not a fix** if the same request still returns `4xx`/`5xx`, or the backend execution still fails.
- **Failed attempts contaminate later ones** through leftover code, seeded state, or browser state. Clean up only your own changes and consider a fresh browser session between materially different attempts.

## Guardrails

- Do not start coding before you can restate the expected behavior in one or two sentences.
- Do not claim success from code inspection, green unit tests, or a visually cleaner UI alone.
- Do not keep broadening the investigation unless the triage report is clearly wrong. If it is, say so and capture the new evidence before rewriting direction.
- Do not leave the final state ambiguous. End with either a verified fix or an explicit failed-attempt summary.

## Stop conditions

Stop when either:

- one candidate passes local validation **and** headed browser validation (via `north-ui-driver`), or
- all ranked candidates fail and the remaining path is too speculative — then write the failed-attempt summary with the next best hypothesis.

## Additional Resources

- Fix execution checklist: [references/checklist.md](references/checklist.md)
- Fix report template: [references/fix-report-template.md](references/fix-report-template.md)
- Worked example: [references/examples.md](references/examples.md)
- Paths and defaults: [config.json](config.json)
- **Delegated capability skills / agents**:
  - `north-ui-driver` — headed browser validation, session contract, recipes
  - `best-of-n-runner` subagent — isolated git worktrees for ranked attempts
