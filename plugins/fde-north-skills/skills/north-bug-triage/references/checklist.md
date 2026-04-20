# Triage Progress Checklist

Copy this checklist and update it as you go:

```text
Triage Progress for {ISSUE_ID}:
- [ ] Create triage folder: .triage-artifacts-{issue_id}/
- [ ] Restate the bug and collect stable identifiers
- [ ] Explore the Linear issue and relevant code paths
- [ ] Read references/repro-strategy.md and pick layer/auth/data
- [ ] Reproduce (headed Playwright OR captured SQL/API evidence) and save video/artifact
- [ ] Triage artifacts, logs, and support bundles
- [ ] Write final report to .triage-artifacts-{issue_id}/REPORT.md
```

## When to Skip Steps

- **Skip Explore** if the user already provided specific code paths, files, or service names to investigate.
- **Skip Reproduce** only after an explicit `AskQuestion` (see [repro-strategy.md -> ## 3. Ask-to-skip pattern](repro-strategy.md#3-ask-to-skip-pattern-required)), for one of these reasons:
  - The user explicitly requests artifact-only triage.
  - The bug is not reproducible in a browser (e.g., backend-only, async job failure).
  - Reproduction is blocked by access, environment, or data constraints.
- If Reproduce is skipped, you must still capture executable evidence (SQL probe, `curl` capture, failing test) — prose alone does not count. See [repro-strategy.md -> ## 2. If you skip UI repro, you still owe evidence](repro-strategy.md#2-if-you-skip-ui-repro-you-still-owe-evidence).
- **Skip Triage artifacts** if no support bundle or logs exist and browser/SQL/API evidence is sufficient.
- **Never leave a partial video behind.** If Reproduce was started and then abandoned, delete the `.webm` and note the pivot in the report — see [repro-strategy.md -> ## 7. Partial-video contract](repro-strategy.md#7-partial-video-contract-required).

## Minimum Viable Triage

At minimum, a triage should:

1. Restate the bug with stable identifiers
2. Identify the likely failing boundary
3. Provide strongest observables (with at least one captured artifact — video, screenshot, SQL probe, or test)
4. Recommend next checks or request missing data
5. Write the report to `.triage-artifacts-{issue_id}/REPORT.md`
