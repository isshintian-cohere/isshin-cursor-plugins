---
name: north-bug-fix
description: Implement and validate North bug fixes from an existing `.triage-artifacts-{issue_id}/REPORT.md` triage report. Use when a North bug already has a triage report and you need to rank likely fixes, try them from highest-confidence to lowest, validate each attempt with local checks plus a headed Playwright browser and video, and stop on first verified success or after all ranked attempts fail. If `REPORT.md` is missing, tell the user to run `north-bug-triage` first.
---

# North Bug Fix

## Purpose

Use this skill only after `north-bug-triage` produced `.triage-artifacts-{issue_id}/REPORT.md`.

This skill turns a strong triage handoff into one of:

- a verified fix with code changes, focused regression coverage, and browser evidence
- a fix report that explains each ranked attempt and why it passed or failed

If `REPORT.md` is missing, stop and tell the user to run `north-bug-triage` first.

Playwright validation is required for this skill because the goal is to restore the user-visible behavior, not only to make tests pass.

Default order (adapt based on context; skip steps the user already completed):

0. Read the triage report and restate the expected behavior.
1. Rank candidate fixes from most recommended to least.
2. Choose a safe attempt-isolation strategy.
3. Implement the highest-ranked candidate.
4. Run the smallest useful local validation.
5. Validate the expected behavior in a headed Playwright browser with video.
6. If the attempt fails, record why, cleanly discard only your own changes, and continue with the next candidate.
7. Stop on the first verified success or after all ranked candidates fail.
8. Write the final fix report to `.triage-artifacts-{issue_id}/fix/FIX_REPORT.md`.

## Quick Start

See:

- [references/checklist.md](references/checklist.md) for the execution checklist
- [references/fix-report-template.md](references/fix-report-template.md) for the canonical output
- [references/examples.md](references/examples.md) for a worked attempt loop

## Configuration

Defaults, requirements, and paths live in [config.json](config.json). Key settings:

- **Triage report required**: `REPORT.md` must already exist
- **Playwright validation required**: UI validation is part of success
- **Input triage report**: `.triage-artifacts-{issue_id}/REPORT.md`
- **Fix folder**: `.triage-artifacts-{issue_id}/fix`
- **Final fix report**: `.triage-artifacts-{issue_id}/fix/FIX_REPORT.md`
- **Playwright artifacts**: `.triage-artifacts-{issue_id}/playwright`

## Default Inputs

Prefer some combination of:

- a triage report path such as `.triage-artifacts-fde-123/REPORT.md`
- the issue key or URL
- the target branch or repo state
- any existing failing test or reproduction command
- the expected user-visible behavior to restore

Do not start from only a Linear issue or a vague symptom. This skill assumes triage already happened.

## Workflow

### 1. Confirm the handoff

- Check that `.triage-artifacts-{issue_id}/REPORT.md` exists.
- If it is missing, stop and tell the user to run `north-bug-triage` first.
- Read `REPORT.md` fully.
- Extract:
  - expected vs actual behavior
  - repro URL and setup notes
  - strongest observables
  - likely failing boundary
  - code surfaces worth inspecting first
  - hypotheses
  - long-term fixes
  - verification plan
- If the report does not clearly say what success looks like, stop and ask before changing code.
- If the report does not give a usable validation URL or flow, stop and ask before editing.

### 2. Rank fix candidates

- Source candidate fixes from:
  - `Likely Failing Boundary`
  - `Hypotheses`
  - `Long-Term Fixes`
  - `Verification Plan`
- Rank highest to lowest by:
  - evidence match
  - expected blast radius
  - reversibility
  - likelihood of restoring the user-visible behavior
- Prefer the smallest change that directly addresses the highest-confidence hypothesis.
- North-specific ranking heuristics:
  - If the failure starts after kickoff, rank async or back-compat fixes above frontend polling, retry, or toast changes.
  - If the strongest observables are network or API failures, keep UI-only fixes low-ranked unless they also remove the failing request.
  - If the likely boundary is auth or permissions propagation, rank boundary fixes above retries or optimistic UI.
  - If the report names a specific service chain, start inside that chain before broader fallback behavior.

### 3. Isolate attempts safely

- Do not stack mutually exclusive fix attempts in one dirty tree.
- Prefer an isolated branch, worktree, or other scratch environment when:
  - the repo already has unrelated changes
  - multiple candidates touch the same files differently
  - you are not confident you can undo your own attempt cleanly
- Never revert, overwrite, or discard unrelated user changes.
- If you cannot isolate attempts safely, stop and ask for guidance instead of guessing.

### 4. Implement one candidate at a time

- Before editing, state:
  - which hypothesis this attempt addresses
  - what behavior should change if it works
  - the smallest evidence that would prove success
- Keep each attempt narrow and evidence-driven.
- Add or update focused regression coverage when it materially reduces the chance of re-breaking the same path.

### 5. Validate locally first

- Run the smallest deterministic check that matches the attempted change:
  - focused unit or integration tests
  - targeted build or typecheck
  - endpoint- or service-level verification
- If the local signal is clearly negative, record the failure and move to the next candidate instead of forcing browser validation.

### 6. Validate in a headed Playwright browser with video

- Use the `playwright-cli` skill for browser actions.
- Start a validation session with:

```bash
bash "$HOME/.cursor/skills/north-bug-fix/scripts/start_validation.sh" \
  <session_name> <url> <playwright_output_dir> [--browser chrome]
```

- This wrapper reuses the triage skill's `start_repro.sh` so repro and verification share the same headed-browser and video flow.
- Re-run the same user-visible path described in the triage report.
- Save:
  - session name
  - video path
  - snapshots
  - any key console or network evidence
- A fix only counts as passed when:
  - the expected behavior happens in the browser
  - the previous symptom no longer appears
  - the browser, network, or API evidence implicated by triage no longer shows the same failure
- If auth or SSO blocks the flow, ask the human to complete only that manual step in the Playwright-controlled window, then resume.

### 7. Handle failed attempts explicitly

- After a failed attempt, record:
  - what changed
  - what validation ran
  - why the attempt failed
  - what new evidence, if any, changes the ranking
- Before the next attempt, discard only your own changes or move to a fresh isolated attempt environment.
- If browser state may have influenced the result, start the next attempt with a fresh Playwright session or profile.
- Do not let leftovers from a failed attempt contaminate the next candidate.

### 8. Stop conditions

Stop when either:

- one candidate passes local validation plus headed Playwright validation, or
- all ranked candidates fail and the remaining path is too speculative

## Gotchas

- A green toast, happy empty state, or optimistic success indicator can be a false positive. If triage implicated an async path such as `inngest-server`, `toolkit-backend`, or `toolkit-task-runner`, require the underlying request or execution evidence to go clean too.
- Triage repro URLs go stale. If the route moved, flags changed, or the app now redirects differently, confirm that you are validating the same flow before concluding the bug disappeared.
- Reusing a persistent Playwright profile can hide the bug by preserving auth, cached data, or completed setup. If behavior changes unexpectedly across attempts, start fresh.
- Auth and SSO must happen inside the Playwright-controlled browser window. Logging in somewhere else produces misleading results.
- A frontend-only change that suppresses an error banner is not a fix if the same request still returns `4xx` or `5xx`, or if the backend execution still fails.
- Failed attempts can contaminate later ones through leftover code, seeded state, or browser state. Clean up only your own changes and consider a fresh browser session between materially different attempts.

## Guardrails

- Do not start coding before you can restate the expected behavior in one or two sentences.
- Do not claim success from code inspection, green unit tests, or a visually cleaner UI alone.
- Do not keep broadening the investigation unless the triage report is clearly wrong; if it is, say so and capture the new evidence.
- Do not leave the final state ambiguous. End with either a verified fix or an explicit failed-attempt summary.

## Output

Write the final implementation result to `.triage-artifacts-{issue_id}/fix/FIX_REPORT.md`.

Use [references/fix-report-template.md](references/fix-report-template.md) as the canonical template. Keep the ranking table in original order, add one attempt section per attempted fix, and record the winning evidence or the failed-attempt summary.

## Additional Resources

- Headed validation wrapper: [scripts/start_validation.sh](scripts/start_validation.sh)
- Paths and defaults: [config.json](config.json)
- Fix execution checklist: [references/checklist.md](references/checklist.md)
- Fix report template: [references/fix-report-template.md](references/fix-report-template.md)
- Worked example: [references/examples.md](references/examples.md)
