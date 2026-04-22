# Bug Fix Report Template

Use this template for the final implementation report at `.triage-artifacts-{issue_id}/fix/FIX_REPORT.md`.

The goal is to preserve the ranked fix attempts, the winning change if one exists, and the evidence that proves the expected behavior is restored.

```markdown
## Issue
- Linear:
- Title:
- Triage report:
- Triage folder:
- Validation URL:
- Expected behavior:

## Candidate Ranking
Add one row per ranked candidate and keep the original ranking order.

| Rank | Candidate fix | Why ranked here | Code surfaces | Status |
|---|---|---|---|---|
| 1 | ... | ... | ... | planned / failed / passed / not attempted |
| 2 | ... | ... | ... | planned / failed / passed / not attempted |
| ... | ... | ... | ... | ... |

## Attempt Log
Repeat this section once per attempted fix, in the same order as the ranking table.

### Attempt <n>
- Ranked candidate:
- Hypothesis addressed:
- Change summary:
- Files touched:
- Local validation:
- Playwright session:
- Video path:
- Browser or network evidence:
- Result: passed / failed
- Evidence:
- Why this did or did not resolve the bug:

### Attempt <n+1>
- Ranked candidate:
- Hypothesis addressed:
- Change summary:
- Files touched:
- Local validation:
- Playwright session:
- Video path:
- Browser or network evidence:
- Result: passed / failed
- Evidence:
- Why this did or did not resolve the bug:

Add more attempt sections as needed.

## Final Result
- Status: passed / all-ranked-fixes-failed
- Winning attempt:
- Final change summary:
- Regression coverage added or updated:
- Remaining risks:
- Recommended next step:

## Evidence
- Browser evidence:
- Test or build evidence:
- Additional artifacts:
```

## Notes

- Keep attempts in the original ranking order, even if new evidence changes confidence later.
- If the first attempt succeeds, still include the lower-ranked candidates in the table as `not attempted`.
- Include the final Playwright video path whenever browser validation ran.
- If the UI looked fixed but the same request or async execution still failed, mark the attempt as `failed`, not `passed`.
- Prefer concrete file paths, commands, and observables over vague summaries.
