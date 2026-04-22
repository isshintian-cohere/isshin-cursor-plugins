# Bug Triage Report Template

Use this template for the final triage report at `.triage-artifacts-{issue_id}/REPORT.md`.

It works both for incomplete triage and for downstream implementation or verification follow-up work.
The goal is to make the next agent productive without forcing it to repeat issue intake, reproduction setup, or boundary discovery.

```markdown
## Issue
- Linear:
- Title:
- Environment:
- Feature area:
- Customer:
- Stable identifiers:
- Triage folder:

## Summary
[One short paragraph describing the symptom, expected behavior, and current best interpretation.]

## Reproduction
- Status: reproduced / not reproduced / partially reproduced
- Repro environment:
- Repro URL:
- Login/setup notes:
- Video path:
- Browser evidence:

## Strongest Observables
- ...
- ...
- ...

## Likely Failing Boundary
- Smallest likely failing boundary:
- Likely service chain:
- Likely user-visible boundary:

## Code Surfaces Worth Inspecting First
- `path/to/file_or_module`
- `path/to/file_or_module`
- `path/to/file_or_module`

## Hypotheses
| Hypothesis | Confidence | Supporting Evidence | Conflicting Evidence | Fastest Confirming Check |
|---|---|---|---|---|
| ... | high / medium / low | ... | ... | ... |
| ... | high / medium / low | ... | ... | ... |

## Immediate Mitigation
- ...
- ...

## Long-Term Fixes
- ...
- ...

## Verification Plan
- Smallest check to validate the leading hypothesis:
- Regression test or assertion to add:
- Browser or product flow to re-run:
- Logs or artifacts to re-check:

## Gaps
- ...
- ...

## Requested Human Help
- [Only include if needed. State the minimum manual step, missing access, or artifact request.]

## Recommended Next Agent Tasks
- Implementation agent:
- Verification agent:
- Artifact/log follow-up agent:
```

## Notes

- Fill in only what is known. Do not invent certainty.
- Prefer concrete file paths, routes, IDs, and URLs over vague summaries.
- Include the saved repro video path whenever a browser repro was run.
- Keep hypotheses actionable. Each one should have a smallest confirming check.
- If the triage is incomplete, use this template anyway and make the gaps explicit.
