# Session Contract

Two rules every user of `north-ui-driver` must follow before handing off a video as evidence: the **SSO handoff** pattern and the **partial-video contract**. Both exist because a misleading artifact costs more review time than no artifact at all.

## SSO handoff

Guessing auth is the single biggest time sink in a browser repro. Before calling `start_session.sh`, pick the right path:

| Environment | Auth path | Notes |
|---|---|---|
| Local stack (`http://localhost:4000`) | `/register` with password | Fastest. `/register` lands you on `/onboarding` → Skip → Home. See [north-ui-recipes.md → Register a throwaway user](north-ui-recipes.md#recipe-register-a-throwaway-user-local-password-auth). |
| Local stack, need admin role | Admin UI `/admin/` → System Admin static connector | See [admin-ui-recipes.md → Log into admin (local)](admin-ui-recipes.md#recipe-log-into-admin-local-dev-static-system-admin-connector). |
| Staging | SSO via in-window human login | Ask the user via `AskQuestion` to complete SSO in the Playwright-controlled window. **Do not** send them to a separate browser — cookies won't transfer. |
| Customer environment | No direct access | Ask the caller to fall back to artifact-only analysis (or the `north-support-bundle` skill). |
| API-only probe | Bearer token | Use `ADMIN_API_URL(/auth/login/local)` for local, or the test-client helpers under `src/backend/tests/**`. Do not try to mint tokens by hand. |

### The pause-for-human pattern

When SSO is required:

1. Run `start_session.sh` to open the headed browser at the login page.
2. Call `AskQuestion` with a message like:
   > "I've opened the Playwright-controlled window at `<login URL>`. Please complete SSO in *that* window (not a separate one) and tell me when you're past the login. I'll resume from there."
3. Wait for the user to confirm. Resume with `playwright-cli -s=<S> snapshot` to pick up the post-login state.
4. If the popup flow opens a second tab, close the popup after SSO with `tab-close` before snapshotting — otherwise `snapshot` may still target the popup.

**Never** send the user to a separate browser window for SSO. Session cookies are bound to the Playwright profile and do not transfer.

## Partial-video contract

Videos in an artifact folder are one of the first things a reviewer opens. A video that ends on the login screen is worse than no video — it implies an aborted investigation and makes the whole artifact bundle look careless.

**Rule**: if you open a Playwright session but do not complete a meaningful flow, you MUST either

- finish the flow (preferred), or
- call `playwright-cli -s=<session> video-stop` + `close`, then `rm` the partial `.webm` file.

A "meaningful flow" is at least one of:

- the symptom was reproduced on screen;
- the negative control was demonstrated (e.g. the same query format that *does* work);
- a screenshot of the failing component was captured with `--filename=`.

If you pivot from UI to SQL/API mid-session, delete the partial video *and* add a note to the calling skill's report (e.g. `REPORT.md` → *Reproduction* or `FIX_REPORT.md` → *Attempt Log*) explaining the pivot. The report's *Reproduction* section must never list a video path that doesn't demonstrate the bug.

## Checklist before you call `start_session.sh`

- [ ] I know my auth path (register / SSO / admin connector / API token).
- [ ] I have the relevant recipe file open (`north-ui-recipes.md` or `admin-ui-recipes.md`).
- [ ] I have `playwright-cli-gotchas.md` handy for when refs go stale or `screenshot --filename` trips me up.
- [ ] I have a failure state and a negative-control query in mind (so the video shows both).
- [ ] I have a plan for what to do if SSO is required (in-window pause + `AskQuestion`).

If any box is unchecked, fix it before opening the browser.
