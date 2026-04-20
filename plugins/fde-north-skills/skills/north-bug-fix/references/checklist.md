# Fix Progress Checklist

Copy this checklist and update it as you go:

```text
Fix Progress for {ISSUE_ID}:
- [ ] Confirm .triage-artifacts-{issue_id}/REPORT.md exists; otherwise tell the user to run north-bug-triage first
- [ ] Restate expected behavior, validation target, and the strongest passing signal
- [ ] Rank candidate fixes from most recommended to least
- [ ] Create .triage-artifacts-{issue_id}/fix/FIX_REPORT.md
- [ ] Implement the highest-ranked attempt
- [ ] Run the smallest useful local validation
- [ ] Run headed Playwright validation with video plus network or console evidence
- [ ] If failed, record why, reset only your changes, and consider a fresh Playwright session or profile
- [ ] Repeat until the first verified pass or all ranked attempts fail
- [ ] Finalize .triage-artifacts-{issue_id}/fix/FIX_REPORT.md
```

## When to Stop Early

- **Stop immediately** if `REPORT.md` is missing. Tell the user to run `north-bug-triage` first.
- **Stop before editing** if the triage report does not clearly define expected behavior.
- **Stop before editing** if the report does not provide a usable validation URL or flow.
- **Stop before attempt 2+** if you cannot safely isolate or undo your own previous attempt.
- **Stop after a passing attempt** once local checks and headed Playwright validation both support the fix.
- **Stop after all ranked attempts fail** and end with an explicit failed-attempt summary plus the next best hypothesis.
