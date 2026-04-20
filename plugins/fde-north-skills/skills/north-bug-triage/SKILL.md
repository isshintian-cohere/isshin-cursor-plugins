---
name: north-bug-triage
description: Triage North bugs given Linear issue IDs. Use when investigating FDE/BE/FE Linear issues/tickets, reproducing North UI or Admin UI bugs, analyzing support bundles, or debugging North backend/frontend failures.
---

# North Bug Triage

## Purpose

Use this skill to move from a reported bug symptom to a Markdown report that contains:

- the smallest likely failing boundary
- the strongest observables
- the next highest-value checks
- immediate mitigations and long-term fixes

Default order (adapt based on context — skip steps when the user already provided that information or when a step is impossible):

1. Fetch Linear context: Fetch the Linear issue context using the `linear-cli` skill. Use `scripts/fetch_linear_context.sh` to fetch the Linear issue context and save it multiple files in the `.triage-artifacts-{issue_id}/linear` directory.
2. Explore: Explore the North codebase based on the Linear context to identify the relevant code paths and files to inspect.
3. Reproduce: Reproduce the bug in a headed browser using the Playwright CLI skill. Use `scripts/start_repro.sh` to start a headed browser session and record the video.
4. Triage: Analyze the artifacts, logs, and support bundles (if available)
5. Iterative Clarification through human-in-the-loop: Ask the user questions for more context if needed and repeat previous steps 1-3 iteratively until the evidence is strong enough to generate a triage report. In addition, address any user's questions or push-back.
6. Generate Report: When the evidence is strong enough, offer to generate a triage report that downstream implementation agents/developers can refer to.

## Quick Start

See [references/checklist.md](references/checklist.md) for the progress checklist and guidance on when to skip steps.

## Configuration

Environment URLs and default paths are in [config.json](config.json). Key settings:

- **Local North UI**: `http://localhost:4000`
- **Admin UI**: `http://localhost:5001/admin/`
- **Output directory**: `.triage-artifacts-{issue_id}`
- **Postgres**: `postgresql://postgres:postgres@localhost:5432/north`
- **OpenFGA**: `http://localhost:8080`

All artifacts for a triage session go in a single folder named `.triage-artifacts-{issue_id}` (e.g., `.triage-artifacts-fde-123`).

## Utility Scripts

- `scripts/fetch_linear_context.sh <ISSUE_ID> [TRIAGE_DIR]`
  - Saves a single consolidated `linear-context.md` for the Explore step, with sections: `Metadata`, `Artifact Index`, `Description`, `Comments`.
  - Keeps remote file URLs by default and does not download attachments.
  - Output Path: `.triage-artifacts-{issue_id}/linear-context.md`
- `scripts/start_repro.sh <SESSION_NAME> <URL> [OUTPUT_DIR]`
  - Opens a headed Playwright session, verifies that it is visible, and starts video recording for the Reproduce step.
  - Output Path: `.triage-artifacts-{issue_id}/playwright/`

## Default Inputs

Prefer some combination of:

- Linear issue key, URL, or pasted bug report
- affected URL, page, or browser flow
- screenshots or user repro steps
- relevant repo code
- support bundles or exported logs
- environment, version, and timestamps

## Workflow

### 1. Restate the bug

Capture:

- expected vs actual behavior
- environment, version, timestamps, customer, and feature area
- stable identifiers such as issue key, request ID, execution ID, conversation ID, agent ID, or data connection ID

### 2. Explore first

- If the issue lives in Linear, use the `linear-cli` skill first.
- Pull the issue title, description, labels, assignee, comments, related issues, and attachment metadata.
- Treat the Linear issue description as the main routing signal for the codebase.
- Do not download or inspect support bundles yet unless the user explicitly asks for artifact-only triage or reproduction is impossible.
- Use the issue description to identify the smallest relevant code path and read only the 2-4 highest-signal files or modules first.
- Aim to understand:
  - expected product behavior
  - likely execution path
  - likely frontend or backend boundary
  - concrete symbols, routes, and services to watch during reproduction

### 3. Reproduce in browser

- **Before opening the browser**, read [references/repro-strategy.md](references/repro-strategy.md). Its 60-second checklist decides whether to reproduce at all, which layer (SQL / API / UI), which auth path, and what data needs to pre-exist. Skipping it is the single biggest source of wasted time in this skill.
- If the bug is visible in the web UI, starts from a user interaction, depends on navigation, or may involve client state, use the Playwright CLI skill.
- Start the repro with `scripts/start_repro.sh`; it opens a headed browser, prepares a named session/profile, and starts video recording.
- For concrete, copy-pasteable UI flows (register a throwaway user, create an agent, reach the sharing picker, etc.), use [references/north-ui-recipes.md](references/north-ui-recipes.md) for the end-user web app and [references/admin-ui-recipes.md](references/admin-ui-recipes.md) for the `/admin/` app. Do not improvise flows that already have a recipe.
- For tool-level quirks (`screenshot --filename=`, profile-reuse `TypeError`, ref staleness, ffmpeg install, etc.), use [references/playwright-cli-gotchas.md](references/playwright-cli-gotchas.md) before working around errors by hand.
- Use `snapshot`, console logs, network evidence, and `eval` to create the smallest reliable repro.
- If auth or SSO blocks the flow, pause and ask the human to finish the manual step in the Playwright-controlled window, then resume. For local stacks, prefer the `/register` recipe — it is faster and keeps the session clean.
- Treat browser evidence as a first-class signal, not a last resort.

### 4. Triage artifacts after exploration and reproduction

- Only after steps 2 and 3, download support bundles, logs, or other artifacts referenced in the Linear issue or its comments. Start with `linear-context.md`'s **Artifact Index** section, produced by `scripts/fetch_linear_context.sh`.
- Decide how many support bundles are present by scanning the Artifact Index against the pattern in [artifact-guide.md -> ## Recognizing a support bundle](references/artifact-guide.md#recognizing-a-support-bundle). Proceed automatically on exactly one match; use `AskQuestion` with the structured options in [artifact-guide.md -> ## Before Downloading](references/artifact-guide.md#before-downloading) when there are zero or multiple matches.
- Follow [artifact-guide.md](references/artifact-guide.md) for bundle selection, first files to inspect, service mapping, and correlation strategy.
- Avoid `secrets/` and `secrets-errors/` unless explicitly authorized and absolutely necessary.
- Keep 1-3 evidence-backed hypotheses and note the fastest confirming check for each.

### 5. Iterative clarification (human-in-the-loop)

- If the evidence is still weak, stop and ask clarifying questions; repeat steps 2-4 iteratively until the evidence is strong enough to report.
- Request missing timestamps, issue comments, log windows, support bundles, screenshots, or manual validations as needed.
- If the next best check requires privileged access or a manual product step, ask the human to perform only that step.
- Address any user questions or push-back before moving on to report generation.

### 6. Generate the triage report

- Only proceed once the evidence is strong enough to stand on its own for a downstream implementer.
- Offer to generate the report before writing it, so the user can confirm scope and format.
- Write the final report to `.triage-artifacts-{issue_id}/REPORT.md` using [references/triage-report-template.md](references/triage-report-template.md) as the canonical template.
- Fill in only what is known and make gaps explicit rather than speculating.

## Gotchas

- The Linear issue body is often high level, but the best repro details often live in comments. Read both before deciding which code path to inspect.
- Attachment-like evidence can appear in `attachments`, markdown links in the issue body, or uploaded files linked inside comments. Do not assume one source has everything.
- **Support bundle ambiguity**: If zero or multiple support bundles are found in `linear-context.md`'s Artifact Index, do not guess. Call `AskQuestion` with the structured options from [artifact-guide.md -> ## Before Downloading](references/artifact-guide.md#before-downloading) (e.g., proceed without, request from customer, pick most recent, pick by timestamp).
- During Explore, keep attachment URLs remote. Do not download support bundles early unless the user explicitly wants artifact-only triage or reproduction is impossible.
- **Do not `curl`-ping URLs to check if the local stack is up.** Use `docker ps`, `lsof -iTCP -sTCP:LISTEN`, or the IDE `terminals/` folder metadata instead.
- **Skipping Reproduce requires an `AskQuestion`, not a unilateral decision.** The only valid skip categories are *artifact-only triage*, *non-browser bug*, and *blocked access/data*; each must be confirmed with the user via `AskQuestion` that offers an alternative (see [repro-strategy.md -> ## 3. Ask-to-skip pattern](references/repro-strategy.md#3-ask-to-skip-pattern-required)). "Code looks clear" and "setup is slow" are never valid. Never flip the todo to `cancelled` without asking first.
- **Partial-video rule.** If you open a Playwright session but do not complete a meaningful flow (symptom on screen, negative control on screen, or a failing-component screenshot), you MUST either finish the flow *or* call `video-stop` + `close` and `rm` the partial `.webm` before writing the report. Videos that end on the login or connector-selection page are actively misleading to reviewers. See [repro-strategy.md -> ## 7. Partial-video contract](references/repro-strategy.md#7-partial-video-contract-required).
- **If you skip UI repro, you still owe captured evidence.** A SQL probe saved to `.triage-artifacts-{issue_id}/sql-evidence.txt`, a `curl` capture saved to `api-evidence.txt`, or a failing pytest — never just prose. See [repro-strategy.md -> ## 2. If you skip UI repro, you still owe evidence](references/repro-strategy.md#2-if-you-skip-ui-repro-you-still-owe-evidence).
- Always pass `--headed` to Playwright and verify the session with `playwright-cli list`. Do not assume a visible browser appeared.
- If login is required, the human must complete SSO inside the Playwright-controlled window and profile, not in a separate browser window. For local stacks with password auth, `/register` is faster — see the recipe in [north-ui-recipes.md](references/north-ui-recipes.md#recipe-register-a-throwaway-user-local-password-auth).
- `playwright-cli video-start` may fail until ffmpeg is installed. Install it with `npx playwright install ffmpeg`, then retry. More tool-level quirks (profile-reuse `TypeError`, `screenshot --filename=` flag, stale refs) are catalogued in [playwright-cli-gotchas.md](references/playwright-cli-gotchas.md).
- Element refs from `snapshot` go stale after navigation, modal dismissal, typing, or any UI state change. Re-run `snapshot` often, or use stable selectors (`role=`, `placeholder=`, `name=`). Reflex admin components invalidate refs even more aggressively than the Next.js app — see [admin-ui-recipes.md -> ## Reflex-specific gotchas](references/admin-ui-recipes.md#reflex-specific-gotchas).
- Save the final video path in the triage report. If the path is missing, the repro artifact is easy to lose.

## Guardrails

- Do not skip code exploration and browser reproduction just because a support bundle exists.
- Do not use headless Playwright when human review or demo capture matters.
- Do not broad-search the whole repo until the likely failing surface is identified.
- Do not present speculation as a finding.
- If blocked by auth, missing access, or missing artifacts, stop and ask for the minimum human assist needed.

## Additional Resources

- Use the `linear-cli` skill to fetch issue context, comments, attachments, and artifacts.
- Use the Playwright CLI skill for headed reproduction and video capture.
- Use `scripts/fetch_linear_context.sh` for a repeatable Explore-phase Linear export.
- Use `scripts/start_repro.sh` for a repeatable headed-browser repro setup.
- Environment URLs and paths: [config.json](config.json)
- Progress checklist: [references/checklist.md](references/checklist.md)
- **Reproduction strategy (read before opening a browser)**: [references/repro-strategy.md](references/repro-strategy.md) — decision tree for layer/auth/data choices, the ask-to-skip pattern, and the partial-video contract.
- **North UI recipes** (end-user web app): [references/north-ui-recipes.md](references/north-ui-recipes.md) — register, create agent, reach sharing picker, chat, settings, My Drive, logout.
- **Admin UI recipes** (`/admin/`, Reflex): [references/admin-ui-recipes.md](references/admin-ui-recipes.md) — log in via static connector, create user, add group, toggle feature flags, view audits.
- **playwright-cli gotchas**: [references/playwright-cli-gotchas.md](references/playwright-cli-gotchas.md) — command-name quirks, profile-reuse `TypeError`, ref staleness, error taxonomy.
- Triage report template: [references/triage-report-template.md](references/triage-report-template.md)
- Support bundle artifact priorities: [references/artifact-guide.md](references/artifact-guide.md)
- Worked North example with full verification loop: [references/examples.md](references/examples.md)
