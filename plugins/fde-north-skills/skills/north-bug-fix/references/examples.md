# Worked Example

## Triage Report Input

Input:

- triage report: `.triage-artifacts-fde-514/REPORT.md`
- expected behavior: legacy automations should execute successfully after upgrade
- likely boundary: `toolkit-backend` -> `inngest-server` -> `toolkit-task-runner`
- top code surfaces:
  - `src/backend/services/inngest/automations/workflow.py`
  - `src/backend/tests/vcr/automations/test_legacy_compat.py`

## Candidate Ranking

1. Add back-compat handling for legacy automation payload shapes in the workflow path.
2. Add a frontend retry or alternate polling state after kickoff.
3. Add broader task-runner fallback behavior.

Why this ranking:

- Attempt 1 matches the strongest evidence and smallest likely boundary.
- Attempt 2 touches the UI but the triage report already showed the failure happens after kickoff.
- Attempt 3 is broader and riskier than necessary.

## Attempt Loop

### Attempt 1

Implementation:

- Added legacy payload normalization in the workflow entrypoint.
- Added a regression test for pre-upgrade automation data.

Local validation:

- Focused backend regression test passed.

Browser validation:

```bash
bash "$HOME/.cursor/skills/north-bug-fix/scripts/start_validation.sh" \
  verify-attempt-1 \
  https://stg.demo.cloud.cohere.com/automations \
  .triage-artifacts-fde-514/playwright
```

Result:

- The previously failing automation completed successfully.
- The validation video showed a green success state.
- No matching `500` errors appeared in browser evidence for the same flow.
- Because the async execution path also completed cleanly, this counts as a real pass rather than a UI-only false positive.

Outcome:

- Stop after attempt 1 because the expected user-visible behavior is restored.
- Mark attempts 2 and 3 as `not attempted` in `FIX_REPORT.md`.

## Alternate Example: Failed First Attempt

If attempt 1 had failed:

1. If the UI looked green but the same `500` errors or failed execution history still appeared, mark attempt 1 as `failed`, not `passed`.
2. Record the failure in `FIX_REPORT.md` with the video path and exact symptom.
3. Discard only the changes from attempt 1 or move to a fresh isolated attempt environment.
4. If profile state may have masked the bug, start attempt 2 with a fresh Playwright session or profile.
5. Re-rank if the failure changes confidence.
6. Implement attempt 2 and repeat local plus headed Playwright validation.

What matters is not trying many ideas quickly. It is preserving a clean evidence trail between attempts.
