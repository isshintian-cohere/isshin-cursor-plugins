---
name: north-bug-triage
description: Triage North bugs given Linear issue IDs. Use when investigating FDE/BE/FE Linear issues/tickets, reproducing North UI or Admin UI bugs, analyzing support bundles, or debugging North backend/frontend failures.
---

# North Bug Triage

## Purpose

Orchestrate the bug-triage workflow: Linear context → exploration → browser repro → artifact analysis → clarification → triage report. The triage report lives at `.triage-artifacts-{issue_id}/REPORT.md` and feeds directly into `north-bug-fix`.

This skill owns the **ordering** — Explore before downloading artifacts, ask-to-skip before cancelling repro, report only when evidence is strong. The capability work is delegated:

- Browser repro → `north-ui-driver` skill
- Support-bundle analysis → `north-support-bundle` skill
- Mid-triage Linear refresh (new comments/attachments) → `linear-cli` skill

## Default order

Adapt based on context; skip a step only when the user already covered it or the step is genuinely impossible:

1. **Fetch Linear context** — run `scripts/fetch_linear_context.sh <ISSUE_ID>` to produce `.triage-artifacts-{issue_id}/linear-context.md` with sections *Metadata*, *Artifact Index*, *Description*, *Comments*. Use the `linear-cli` skill to refresh if the user uploads new comments or attachments mid-triage.
2. **Explore** — read the Linear context to identify the smallest likely failing boundary and the 2–4 highest-signal files. **Do not download artifacts yet.**
3. **Reproduce** — if the bug is browser-visible, use the `north-ui-driver` skill. Otherwise follow the *ask-to-skip* rule below.
4. **Triage artifacts** — if the Linear Artifact Index lists any support bundles, use the `north-support-bundle` skill (it owns bundle identification, ambiguity resolution, download, and correlation).
5. **Clarify** — if evidence is still weak, `AskQuestion` and loop on 2–4.
6. **Report** — write `.triage-artifacts-{issue_id}/REPORT.md` using [references/triage-report-template.md](references/triage-report-template.md).

## Configuration

Environment URLs and paths: [config.json](config.json). Output root: `.triage-artifacts-{issue_id}`.

## Triage-specific rules

### Explore before downloading artifacts

The Linear issue description is the best routing signal into the codebase. Downloading bundles before exploring often makes the triage over-index on log-shaped evidence and miss the real code path. Only move to artifact analysis (step 4) once you have at least one concrete code-surface hypothesis from step 2.

### Ask-to-skip the Reproduce step

Skipping step 3 requires an explicit `AskQuestion`, never a unilateral decision. Valid skip categories:

- **artifact-only triage** — the user already asked for bundle-only analysis
- **non-browser bug** — backend-only, async job, migration, CLI, etc.
- **blocked access/data** — SSO you cannot complete, customer environment, missing seed data

"Code looks clear" and "setup is slow" are **never** valid reasons. Never flip the Reproduce todo to `cancelled` without asking first. Sample `AskQuestion` options:

- "Skip UI repro: backend/SQL repro is sufficient (I will save SQL evidence)"
- "Attempt UI repro: I will register a throwaway user locally via `/register`"
- "Attempt UI repro: please complete SSO in the Playwright window when prompted"
- "Attempt UI repro: please seed this specific user/agent/group first"

### If you skip UI repro, you still owe evidence

A triage where the browser step is skipped must still produce *something* executable in the triage folder — a SQL probe saved to `.triage-artifacts-{issue_id}/sql-evidence.txt`, a `curl` capture saved to `api-evidence.txt`, or a minimal pytest reproducer under `src/backend/tests/**` that fails before the fix. Prose alone ("I read the code and it's obviously this") does not count.

### Clarify through human-in-the-loop

Stop and ask clarifying questions the moment evidence is weaker than needed — missing timestamps, missing repro steps, missing log windows, missing privileges. Loop back through 2–4 with the new information. Address any user questions or push-back before moving on to report generation.

## Gotchas

- The Linear issue body is often high level; the best repro details live in comments. Read both before deciding which code path to inspect.
- Attachment-like evidence can appear in `attachments`, markdown links in the issue body, or uploaded files linked inside comments. Do not assume one source has everything.
- **Do not `curl`-ping URLs to check if the local stack is up.** Use `docker ps`, `lsof -iTCP -sTCP:LISTEN`, or the IDE `terminals/` folder metadata instead.
- During Explore, keep attachment URLs remote. Do not download bundles early unless the user explicitly wants artifact-only triage or reproduction is impossible.
- When the browser repro is running via `north-ui-driver`, that skill owns the partial-video contract and SSO handoff — follow its rules and cite its video path back in `REPORT.md`.

## Guardrails

- Do not skip code exploration and browser reproduction just because a support bundle exists.
- Do not broad-search the whole repo until the likely failing surface is identified.
- Do not present speculation as a finding.
- If blocked by auth, missing access, or missing artifacts, stop and ask for the minimum human assist needed.

## Additional Resources

- Progress checklist: [references/checklist.md](references/checklist.md)
- Worked North example: [references/examples.md](references/examples.md)
- Triage report template: [references/triage-report-template.md](references/triage-report-template.md)
- Linear context fetch: [scripts/fetch_linear_context.sh](scripts/fetch_linear_context.sh)
- **Delegated capability skills**:
  - `north-ui-driver` — headed browser repro, recipes, session contract
  - `north-support-bundle` — bundle identification, download, service correlation
  - `linear-cli` — mid-triage Linear refresh for new comments/attachments
