# Triage Progress Checklist

Copy this checklist and update it as you go:

```text
Triage Progress for {ISSUE_ID}:
- [ ] Create triage folder: .triage-artifacts-{issue_id}/
- [ ] Restate the bug and collect stable identifiers
- [ ] Explore the Linear issue and relevant code paths
- [ ] Pick repro layer (SQL / API / UI); confirm auth path and seed data
- [ ] Reproduce (headed Playwright via north-ui-driver OR captured SQL/API evidence)
- [ ] Triage artifacts via north-support-bundle (if bundles exist)
- [ ] Write final report to .triage-artifacts-{issue_id}/REPORT.md
```

## When to Skip Steps

- **Skip Explore** if the user already provided specific code paths, files, or service names to investigate.
- **Skip Reproduce** only after an explicit `AskQuestion` (see *Ask-to-skip the Reproduce step* in the main SKILL.md), for one of these reasons:
  - The user explicitly requests artifact-only triage.
  - The bug is not reproducible in a browser (backend-only, async job failure, migration, CLI, etc.).
  - Reproduction is blocked by access, environment, or data constraints.
- If Reproduce is skipped, you must still capture executable evidence (SQL probe, `curl` capture, failing test) — prose alone does not count. See *If you skip UI repro, you still owe evidence* in the main SKILL.md.
- **Skip Triage artifacts** if no support bundle or logs exist and browser/SQL/API evidence is sufficient.
- **Never leave a partial video behind.** `north-ui-driver`'s session contract owns this rule — if Reproduce was started and then abandoned, delete the `.webm` and note the pivot in `REPORT.md`.

## Minimum Viable Triage

At minimum, a triage should:

1. Restate the bug with stable identifiers
2. Identify the likely failing boundary
3. Provide strongest observables (with at least one captured artifact — video, screenshot, SQL probe, or test)
4. Recommend next checks or request missing data
5. Write the report to `.triage-artifacts-{issue_id}/REPORT.md`
