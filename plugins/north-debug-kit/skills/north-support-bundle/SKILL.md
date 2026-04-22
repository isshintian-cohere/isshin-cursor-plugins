---
name: north-support-bundle
description: Identify, select, download, and analyze North support bundles. Use when investigating a North bug with attached support bundles, correlating logs across North services (toolkit-backend, toolkit-frontend, inngest-server, task-runner, Atlas, Compass, Dex), or inspecting exported bundle logs — whether or not a Linear ticket is involved.
---

# North Support Bundle Analyzer

## Purpose

Use this skill whenever you need to work with a North support bundle — the `support-bundle-*.tar.gz` archives customers produce via the troubleshoot UI. Three common entry points:

1. A Linear issue has one or more bundle attachments and you want to use them during triage.
2. A customer dropped a bundle directly (no ticket yet) and you want to make sense of it.
3. You already have a triage direction and want to correlate logs across services.

This skill **owns** the bundle identification → ambiguity resolution → download → first-look → service mapping → correlation workflow. It does **not** own the Linear orchestration or browser-repro steps — those live in `north-bug-triage` and `north-ui-driver`.

## Default Inputs

- one or more bundle URLs, local paths, or a Linear issue id whose attachments include bundles (at least one is required)
- optional: the symptom category (frontend, automations, chat, sync, auth) to prioritize which service logs to read first
- optional: an incident timestamp window to help disambiguate between multiple bundles

## Workflow

### 1. Identify bundle candidates

The input varies by entry point:

- **Called from `north-bug-triage`**: the caller has already produced `.triage-artifacts-{issue_id}/linear-context.md`. Scan its **Artifact Index** table for candidate bundles.
- **Called standalone with a Linear id**: run the `linear-cli` skill to list the issue's attachments, or ask the user to paste the bundle URL.
- **Called standalone with a direct drop**: treat the provided URL or local path as the one candidate.

Classify a row (or a raw filename) as a *candidate bundle* if **any** of the following match (case-insensitive):

- the title ends in `.tar.gz` or `.tgz`
- the title or URL contains `support-bundle`
- the title contains "support bundle" or the standalone word "bundle"

See [references/artifact-guide.md → Recognizing a support bundle](references/artifact-guide.md#recognizing-a-support-bundle) for the exact matching rules.

### 2. Resolve ambiguity with `AskQuestion`

Do not guess which bundle to use. Branch on the candidate count:

- **Exactly one candidate, and its metadata matches the incident timestamp and customer**: proceed. Record the bundle URL and source for the caller's report.
- **Zero candidates** — call `AskQuestion` with options:
  - "Proceed without artifact analysis (rely on browser repro and code exploration)"
  - "Request a support bundle from the customer"
  - "Check a specific URL or location the user provides"
  If the user chooses "proceed without", explicitly note the gap in the caller's report (e.g. `REPORT.md` → *Missing evidence*).
- **Multiple candidates, or one candidate whose title/URL disagrees with the incident timestamp or customer** — call `AskQuestion` with options:
  - "Most recent bundle"
  - "Bundle closest to the incident timestamp"
  - "All bundles (compare across them)"
  - "A specific bundle by name or date"
  The wrong bundle can waste significant triage time.

Whichever path is chosen, record the decision and the bundle URL so the choice is auditable.

### 3. Download and first-look

Download the chosen bundle(s):

- When called from triage, place them in `.triage-artifacts-{issue_id}/bundles/`.
- When called standalone, place them in `.bundle-analysis/{name}/` next to the invoking shell's cwd.

Then inspect the *first-look* files listed in [references/artifact-guide.md → Start Here](references/artifact-guide.md#start-here):

- `version.yaml` — bundle collection version
- `helm/*.json` — deployed app version, chart, image tags, env-derived config
- `execution-data/summary.txt` — failed collectors and analyzer gaps
- `analysis.json` — bundle-level analyzer output
- `cluster-resources/pods/*.json` — pod restarts, creation times, readiness
- `cluster-resources/events/*.json` — probe failures, restarts, backoff
- `cluster-resources/pods/logs/**` — service-specific runtime evidence

`helm/*.json` is almost always the cheapest first read — it confirms the deployed patch version and rules out "is this a known regression on this release" in a single shot.

### 4. Choose which service logs to read first

Let the symptom category drive log selection. See [artifact-guide.md → Service Mapping](references/artifact-guide.md#service-mapping) for the per-category maps:

- Frontend and request issues → `toolkit-frontend*.log`, `toolkit-backend*.log`
- Automations and background execution → `inngest-server*.log`, `toolkit-task-runner*.log`, `toolkit-backend*.log`, `helm/*.json`
- Chat and tool execution → `toolkit-backend*.log` (+ tool-specific service logs)
- Sync and indexing → Atlas logs, Compass worker/pipeline logs, parser logs, backend logs for kickoff events
- Auth and access → backend logs, Dex logs, frontend logs

### 5. Correlate across services

Join evidence using high-value fields (in rough order of stability): `request_id`, `trace_id`, `span_id`, `execution_id`, `conversation_id`, `agent_id`, `data_connection_id`, `tool`, `fnVersion`.

If the bundle lacks stable IDs, fall back to narrow timestamp windows, pod-creation times, restart boundaries, or request path plus status code. See [artifact-guide.md → High-Value Correlation Fields](references/artifact-guide.md#high-value-correlation-fields).

Keep 1–3 evidence-backed hypotheses. For each, note: supporting evidence, conflicting evidence, and the fastest confirming check.

### 6. Record findings

Output shape depends on the caller:

- **Called from `north-bug-triage`**: add evidence to `.triage-artifacts-{issue_id}/REPORT.md` under *Strongest Observables* and *Evidence*; note the bundle URL plus any collector gaps under *Gaps*.
- **Standalone**: emit a short `bundle-analysis.md` next to the downloaded bundle with sections: Summary, Strongest Observables, Likely Failing Boundary, Hypotheses, Gaps.

## Gotchas

- **Secrets directories are off-limits.** Avoid `secrets/` and `secrets-errors/` unless explicitly authorized and absolutely necessary.
- **Bundle limitations matter.** Call out post-restart-only windows, missing previous-container logs, failed collectors, and missing troubleshoot-job output explicitly — see [artifact-guide.md → Bundle Limitations To Call Out](references/artifact-guide.md#bundle-limitations-to-call-out). A finding "the logs don't show X" is much weaker if the collector for X failed.
- **Trace-export failures are noise** unless observability itself is the bug.
- **Check deployed version first.** For suspected regressions, compare `helm/*.json` against the issue's reported symptom before deep-reading low-signal logs.
- **"Old objects in new code" is an async-path signal.** When the issue mentions post-upgrade breakage, check for upgrade/version churn signals in async services (Inngest, task-runner) before assuming frontend state corruption.

## Guardrails

- Do not download bundles speculatively. In a triage context, wait until the caller has finished code exploration and browser repro; in a standalone context, download only after the ambiguity pattern above selects one.
- Do not commit bundles or extracted logs to version control. Keep them under `.triage-artifacts-*/` or `.bundle-analysis/`, which should be `.gitignore`'d.
- Do not present speculation as a finding. Every hypothesis in the output needs supporting evidence, a conflicting-evidence note (or "none observed"), and a fastest-confirming check.
- Do not read `secrets/` paths without explicit authorization.

## Additional Resources

- Full bundle guide (first files, service maps, correlation fields, signal vs noise): [references/artifact-guide.md](references/artifact-guide.md)
- Paths and defaults: [config.json](config.json)
- Delegated capabilities:
  - Linear attachment fetching: `linear-cli` skill
  - Browser repro (when the bundle points back at a UI symptom): `north-ui-driver` skill
