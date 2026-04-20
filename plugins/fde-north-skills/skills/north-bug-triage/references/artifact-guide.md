# Support Bundle Artifact Guide

Use this file only after the main `SKILL.md` Explore and Reproduce steps are complete, or when the user explicitly narrows the task to artifact-only triage.

## Recognizing a support bundle

The input for this decision is a single file: `.triage-artifacts-{issue_id}/linear-context.md`, produced by the Explore step. Scan the **Artifact Index** table — each row has `Title / filename | URL | Source`.

Do not re-fetch Linear or scan the repo. Classify an Artifact Index row as a *candidate support bundle* if **any** of the following match (all case-insensitive):

- the **Title** ends in `.tar.gz` or `.tgz`
- the **Title** or **URL** contains `support-bundle`
- the **Title** contains "support bundle" or the standalone word "bundle"

Then branch on the candidate count:

- **Exactly one candidate**: proceed automatically. Record the bundle URL and Source in `REPORT.md` under *Evidence* so the choice is auditable.
- **Zero or multiple candidates**: do not guess. Use `AskQuestion` with the structured options in the next section.
- **One candidate, but its title/URL strongly disagrees with the incident timestamp or customer in `linear-context.md`'s Metadata block**: treat as ambiguous and fall through to the multi-candidate branch.

## Before Downloading

**If no support bundle is found**, ask the user via `AskQuestion` with these options:
- Proceed without artifact analysis (rely on browser repro and code exploration)
- Request a support bundle from the customer
- Check a specific URL or location the user provides

If the user chooses "proceed without", explicitly note the gap in `REPORT.md` under *Missing evidence* so downstream agents know the triage was run without a bundle.

**If multiple bundles are found**, ask the user via `AskQuestion` which to analyze:
- Most recent bundle
- Bundle closest to the incident timestamp
- All bundles (compare across them)
- A specific bundle by name or date

Do not guess which bundle is relevant. The wrong bundle can waste significant triage time.

## Start Here

Check these first in most North bundles:

- `version.yaml`
- `helm/*.json`
- `execution-data/summary.txt`
- `analysis.json`
- `cluster-resources/pods/*.json`
- `cluster-resources/events/*.json`
- `cluster-resources/pods/logs/**`

What they usually answer:

- `version.yaml`: support bundle collection version
- `helm/*.json`: deployed app version, chart version, image tags, service wiring, env-derived config
- `execution-data/summary.txt`: failed collectors and analyzer gaps
- `analysis.json`: bundle-level analyzer output
- `pods/*.json`: pod restarts, creation times, readiness, previous containers
- `events/*.json`: probe failures, restarts, backoff, reschedules
- `pods/logs/**`: service-specific runtime evidence

## Service Mapping

Use the symptom to choose the first services to inspect.

### Frontend and request issues

Read first:

- `toolkit-frontend*.log`
- `toolkit-backend*.log`

Look for:

- request paths
- HTTP status codes
- user-facing exceptions
- auth redirects

Correlate with browser evidence from the repro step:

- prefer repeatable Playwright repro evidence plus console and network data over screenshots alone
- if the UI and backend logs disagree, use network evidence to decide whether the issue is frontend rendering or a backend contract failure

Be careful:

- trace export failures are often noise unless observability itself is the bug

### Automations and background execution

Read first:

- `inngest-server*.log`
- `toolkit-task-runner*.log`
- `toolkit-backend*.log`
- `helm/*.json`

Look for:

- `app/automations/workflow`
- `app/automations/execute_node`
- `inngest/function.failed`
- edge or step execution errors
- `execution_id`
- retries, cancellations, recovery jobs

Interpretation pattern:

- Inngest often shows the failing event and orchestration symptom.
- Task-runner often shows the function registration, HTTP edge handling, or the real stack trace.
- Backend often shows the feature flags, settings, or API call that kicked the workflow off.

### Chat and tool execution

Read first:

- `toolkit-backend*.log`
- any tool-specific service logs if the tool fans out to another service

Look for:

- `request_id`
- `agent_id`
- `conversation_id`
- `tool`
- retry handlers
- model provider errors

### Sync and indexing

Read first:

- Atlas logs
- Compass worker or pipeline logs
- parser logs
- backend logs for kickoff events

Look for:

- `data_connection_id`
- worker names
- indexing failures
- parser or upload errors

### Auth and access

Read first:

- backend logs
- Dex logs
- frontend logs

Look for:

- token failures
- refresh failures
- OIDC callback errors
- unauthorized or forbidden responses

## High-Value Correlation Fields

Prefer joining evidence with these fields:

- `request_id`
- `trace_id`
- `span_id`
- `execution_id`
- `conversation_id`
- `agent_id`
- `data_connection_id`
- `tool`
- `fnVersion`

If the bundle lacks stable IDs, correlate by:

- narrow timestamp windows
- pod creation time
- restart boundaries
- request path and status code

## Investigation Style

Search for observables, not theories.

Start with:

- exact feature terms from the issue
- generic failure terms such as `error`, `exception`, `traceback`, `failed`, `500`, and `timeout`
- browser timestamps, request URLs, request IDs, and visible failures from the repro step

Prefer timestamps and stable IDs that let you correlate events across services.

Keep 1-3 hypotheses. For each one, note:

- supporting evidence
- conflicting evidence
- the fastest next artifact or check that would confirm it

## Common Signal vs Noise

Usually high signal:

- repeated errors on the same feature path
- request IDs that connect multiple services
- `500` responses with matching feature events
- pod restart timing that aligns with the incident
- bundle collector failures that explain missing evidence

Usually lower signal until proven otherwise:

- isolated startup warnings
- unrelated misconfiguration warnings
- observability export failures
- cluster analyzer failures that only describe undersized environments

## Bundle Limitations To Call Out

Explicitly mention these when present:

- the bundle only captured a post-restart window
- the relevant service logs are missing
- previous container logs are not included
- troubleshoot jobs failed to start
- collectors failed
- the issue report lacks repro timing or identifiers

## Practical North Notes

- `helm/*.json` is often the quickest way to verify the actual deployed patch version.
- For suspected regressions, compare the issue title and repro steps against the deployed version before deep-reading low-signal logs.
- When the issue mentions "old" objects breaking "new" behavior, check for upgrade or version churn signals in async services before assuming frontend state corruption.
