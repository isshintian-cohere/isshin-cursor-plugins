# Reproduction Strategy

Use this file in the **Reproduce** step of `SKILL.md` *before* touching Playwright. Reading it takes 60 seconds and prevents the two most common mistakes: reproducing in the wrong layer, and leaving a misleading partial video behind.

The rest of the skill assumes you have already completed the Restate and Explore steps, so you know the likely failing boundary and have at least one stable identifier.

## 1. Decide whether to reproduce at all

Answer these in order:

1. **Is the failure visible in the web UI, or does it depend on a user interaction, navigation, or client state?** If yes, you *should* reproduce in a headed browser and record a video.
2. **Is it a backend-only, async-job, or data-pipeline failure?** Then the UI repro may be unnecessary, and artifact/SQL/API probes are preferred.
3. **Is reproduction blocked by access, environment, or data constraints?** Stop and call `AskQuestion` — this is not a solo decision.

**The skill's contract**: "Code looks clear" and "setup is slow" are **never** valid reasons to skip the UI repro. If you feel tempted to skip because the code is deterministic, treat that as a signal to *shrink* the repro (reproduce at SQL/API level), not to eliminate it.

## 2. If you skip UI repro, you still owe evidence

A triage where the UI step is skipped should produce *something* executable and captured in the triage folder — typically one of:

- a SQL probe saved to `.triage-artifacts-{issue_id}/sql-evidence.txt` that exercises the same predicate the failing route emits;
- a `curl`-based API repro saved to `.triage-artifacts-{issue_id}/api-evidence.txt`;
- a minimal pytest reproducer committed under `src/backend/tests/**` that fails before the fix and passes after.

Prose alone ("I read the code and it's obviously this") is not sufficient.

## 3. Ask-to-skip pattern (required)

If you plan to skip the UI reproduce step for any of the reasons below, call `AskQuestion` first, with options and a one-line justification — do **not** unilaterally skip. This mirrors the support-bundle ambiguity pattern in `artifact-guide.md`.

Valid skip categories (any one requires an `AskQuestion`):

- **artifact-only triage** — the user already asked for bundle-only analysis
- **non-browser bug** — backend-only, async job, migration, CLI, etc.
- **blocked access/data** — SSO you can't complete, customer environment, missing seed data

Sample `AskQuestion` options:

- "Skip UI repro: backend/SQL repro is sufficient (I will save SQL evidence)"
- "Attempt UI repro: I will register a throwaway user locally via `/register`"
- "Attempt UI repro: please complete SSO in the Playwright window when prompted"
- "Attempt UI repro: please seed this specific user/agent/group first"

## 4. Choose the right layer

Pick the smallest layer that reproduces the bug deterministically. Climbing the stack is expensive; coming back down is cheap.

| Evidence needed | Preferred layer | Tool |
|---|---|---|
| SQL predicate / CRUD filter behavior | **Postgres** | `docker exec <db> psql -U postgres -d <db> -c "<SQL>"` |
| Route contract / auth / status code | **HTTP API** | `curl` with bearer token or test-client helpers |
| Service orchestration bug (Inngest, task-runner) | **backend logs + replay** | `make logs service=<name>`; replay via test harness |
| User-visible rendering, client state, navigation | **headed browser** | `playwright-cli` (see `north-ui-recipes.md`, `admin-ui-recipes.md`) |

Climb the stack only when the layer below cannot reproduce the symptom. Example from `FDE-472`: the bug was "user search missing results"; the failing predicate is a single line in `backend/crud/user.py`, so SQL was the right first layer, UI was the confirmation layer, and the API in between was redundant.

## 5. Choose the right auth path

Before `playwright-cli open`, decide how you'll get past the login screen. Guessing here wastes the most time in practice.

| Environment | Auth path | Notes |
|---|---|---|
| Local stack (`http://localhost:4000`) | `/register` with password | Fastest. `/register` lands you on `/onboarding` → Skip → Home. Works for any throwaway account. See `north-ui-recipes.md` → "Register a throwaway user". |
| Local stack, need admin role | Admin UI `/admin/` → System Admin static connector | See `admin-ui-recipes.md` → "Log into admin (local)". |
| Staging | SSO via in-window human login | Ask the user via `AskQuestion` to complete SSO in the Playwright-controlled window. Do **not** send them to a separate browser — cookies won't transfer. |
| Customer environment | No direct access | Force artifact-only triage; confirm via `AskQuestion`. |
| API-only probe | Bearer token | Use `ADMIN_API_URL(/auth/login/local)` for local, or the test-client helpers from `src/backend/tests/**` patterns. Do not attempt to mint tokens by hand. |

## 6. Choose the right data seeding

| Data you need | How to seed it |
|---|---|
| A user who must **appear in UI searches** (and can be referenced, but not logged in as) | Seed directly: `docker exec <db> psql -U postgres -d <db> -c "INSERT INTO users (id, fullname, email, role, has_completed_onboarding, has_accepted_terms_of_service) VALUES (...)"`. No password or OIDC setup needed. |
| A user who must **log in** | Register via `/register` (local) or the Admin UI Create User dialog. DB-seeded rows without passwords cannot authenticate. |
| An agent owned by the sharer | Log in as the sharer, then follow the "Create agent" recipe. |
| A feature flag state | Admin UI → Experiments (see `admin-ui-recipes.md`). |
| An MCP server / tool config | Admin UI → Tools. |

When a recipe requires both a seeded referenceable user *and* a logged-in actor, seed the referenceable one via SQL and register the actor via `/register` — combining both paths in one session. This is the shape used in the `FDE-472` triage.

## 7. Partial-video contract (required)

Videos in the triage folder are one of the first things a reviewer opens. A video that ends on the login screen is worse than no video — it implies an aborted investigation.

**Rule**: if you open a Playwright session but do not complete a meaningful flow, you MUST either

- finish the flow (preferred), or
- call `playwright-cli -s=<session> video-stop` + `close`, then `rm` the partial `.webm` file.

A "meaningful flow" means at least one of:

- the symptom was reproduced on screen;
- the negative control was demonstrated (e.g., the same query format that *does* work);
- a screenshot of the failing component was captured.

If you pivot from UI to SQL/API mid-session, delete the partial video *and* add a note to `REPORT.md` → "Reproduction" explaining the pivot. The report's "Reproduction" section must never list a video path that doesn't demonstrate the bug.

## 8. Checklist before you call `start_repro.sh`

- [ ] I have confirmed in `Restate the bug` which layer I intend to use.
- [ ] I have called `AskQuestion` if I plan to skip UI repro.
- [ ] I know my auth path (register / SSO / admin connector / API token).
- [ ] I know what data needs to pre-exist and have a plan to seed it.
- [ ] I have the relevant recipe file open (`north-ui-recipes.md` or `admin-ui-recipes.md`).
- [ ] I have `playwright-cli-gotchas.md` handy for when refs go stale or `screenshot --filename` trips me up.
- [ ] I have a failure state and a negative-control query in mind (so the video shows both).

If any box is unchecked, fix it before opening the browser.
