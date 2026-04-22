---
name: north-ui-driver
description: Drive the North end-user UI (localhost:4000) and Admin UI (localhost:5001/admin/) in a headed Playwright browser with video recording. Use whenever a North task needs to reproduce, validate, or demonstrate UI behavior — including SSO handoff, ref-staleness recovery, and the canonical register / create-agent / sharing-picker / admin-login flows.
---

# North UI Driver

## Purpose

Use this skill whenever a North task needs a real, headed, video-recorded browser session:

- reproducing a bug in the end-user or admin app
- validating that a fix restored user-visible behavior
- capturing UI evidence (video, screenshot, console, network) for a report
- confirming a feature flag or admin config change end-to-end

This skill is **capability-focused** and owns exactly one workflow: spin up a headed Playwright session against `localhost:4000` or `localhost:5001/admin/`, run a canonical recipe, and leave behind a clean video artifact. It does not own the triage or fix orchestration — those live in `north-bug-triage` and `north-bug-fix`.

## Default Inputs

- **Session name** — typically the Linear issue id (lowercase), e.g. `fde-472`. Used as the playwright-cli `-s` handle and as the video filename prefix.
- **Target URL** — end-user, admin, or a specific route.
- **Output dir** — defaults to `.triage-artifacts-<session>/playwright/`.

## Quick Start

Start a headed, video-recording session:

```sh
bash "$HOME/.cursor/plugins/local/north-debug-kit/skills/north-ui-driver/scripts/start_session.sh" <SESSION_NAME> <URL> [OUTPUT_DIR]
```

The script:

- creates or reuses `<OUTPUT_DIR>/profile/`
- opens headed Chrome against `<URL>`
- verifies via `playwright-cli list` that the session shows `headed: true`
- starts `video-start` and installs `ffmpeg` via `npx playwright install ffmpeg` if missing
- prints the video path — always save it to whatever report is calling this skill

## Configuration

Environment URLs and defaults: [config.json](config.json). Key settings:

- **Local North UI**: `http://localhost:4000`
- **Admin UI**: `http://localhost:5001/admin/`
- **Staging North UI**: `https://stg.demo.cloud.cohere.com/`
- **Staging Admin UI**: `https://stg.demo.cloud.cohere.com/admin/`

## Recipes

Before improvising a flow, check whether a recipe already exists — most North UI and Admin UI flows are catalogued with verified refs and gotchas:

- **End-user app** (`/login`, `/register`, `/agents/new`, sharing picker, chat, `/settings?tab=tools`, `/drive`, `/logout`): [references/north-ui-recipes.md](references/north-ui-recipes.md)
- **Admin app** (`/admin/`, Reflex, static connector login, create user, add group, experiments, audits): [references/admin-ui-recipes.md](references/admin-ui-recipes.md)
- **Tool-level quirks** (`screenshot --filename=`, profile-reuse `TypeError`, ref staleness, ffmpeg, error taxonomy): [references/playwright-cli-gotchas.md](references/playwright-cli-gotchas.md)
- **Session contract** (partial-video rule + SSO handoff pattern): [references/session-contract.md](references/session-contract.md)

## Gotchas

- **Always pass `--headed`.** Headless runs do not record reviewable video and are harder to audit. Verify the session reported `headed: true` via `playwright-cli list`. `start_session.sh` already does this check.
- **Refs go stale.** Snapshots invalidate refs on any navigation, modal open/close, typing, streamed content, or WebSocket-driven Reflex update. Re-snapshot before reusing, or switch to stable selectors (`role=`, `placeholder=`, `name=`). Reflex admin components invalidate refs even more aggressively than the Next.js app — see [playwright-cli-gotchas.md → Ref staleness](references/playwright-cli-gotchas.md#ref-staleness).
- **Persistent profiles hide bugs.** Reusing a profile preserves auth cookies, cached feature flags, and completed onboarding — a "fixed" bug may actually be masked. If behavior changes unexpectedly across sessions, `rm -rf <output_dir>/profile` and start fresh. See [playwright-cli-gotchas.md → Profile reuse TypeError](references/playwright-cli-gotchas.md#profile-reuse-typeerror).
- **SSO must happen inside the Playwright-controlled window.** For staging (or any tenant without password auth), pause and ask the human to complete SSO in the browser the script opened — **not** a separate Chrome window. Cookies won't transfer. For local stacks with password auth, prefer the `/register` recipe. See [session-contract.md → SSO handoff](references/session-contract.md#sso-handoff).
- **Save the final video path** into whatever report calls this skill. A video without a cited path is easy to lose.
- **Partial videos are misleading evidence.** A `.webm` that ends on a login page implies an aborted investigation. Either finish a meaningful flow or `video-stop` + `close` + `rm` the file. See [session-contract.md → Partial-video contract](references/session-contract.md#partial-video-contract).
- **Use `goto`, not `navigate`.** `playwright-cli` has no `navigate` command.
- **`screenshot` takes `--filename=`**, not a positional path. A positional arg is parsed as a CSS selector and throws a parser error.
- **ffmpeg missing**: install once with `npx playwright install ffmpeg`, then retry `video-start`. `start_session.sh` already retries automatically.

## Guardrails

- Do not run this skill headless when the caller expects evidence capture. If headless is genuinely required, skip video and capture explicit screenshots at each decision point.
- Do not hand-edit cookies or the profile directory to impersonate a user — use the correct auth recipe (`/register` locally, Admin UI for roles, in-window SSO for staging).
- Do not leave a partial `.webm` in an artifact folder. Reviewers treat "video ending on login" as a negative signal about the whole triage/fix.

## Closing out

```sh
playwright-cli -s=<SESSION_NAME> video-stop
playwright-cli -s=<SESSION_NAME> close
```

Then record the final video path in the calling skill's report.

## Additional Resources

- Session starter script: [scripts/start_session.sh](scripts/start_session.sh)
- End-user recipes: [references/north-ui-recipes.md](references/north-ui-recipes.md)
- Admin recipes: [references/admin-ui-recipes.md](references/admin-ui-recipes.md)
- Tool quirks: [references/playwright-cli-gotchas.md](references/playwright-cli-gotchas.md)
- Session contract: [references/session-contract.md](references/session-contract.md)
- Paths and defaults: [config.json](config.json)
