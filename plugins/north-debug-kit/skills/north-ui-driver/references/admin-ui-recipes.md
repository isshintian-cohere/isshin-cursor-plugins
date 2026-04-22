# Admin UI Recipes (`/admin/`)

Copy-paste playwright-cli recipes for the North admin app. Mount path locally is `http://localhost:5001/admin/`; on staging it is `https://stg.demo.cloud.cohere.com/admin/`. For end-user flows, see [north-ui-recipes.md](north-ui-recipes.md). For tool-level quirks, see [playwright-cli-gotchas.md](playwright-cli-gotchas.md). For SSO handoff and the partial-video rule, see [session-contract.md](session-contract.md).

**This app is built with Reflex, not Next.js.** That changes a few things:

- Forms use HTML `name=` attributes (e.g. `name="email"`, `name="password"`) rather than React form state. Playwright selectors like `getByRole('textbox', { name: 'Email' })` still work but are matched via the adjacent `<label>`, which Reflex renders as a separate `<Text>` sibling.
- State changes happen via WebSocket round-trips. After every user-triggered state change, allow **at least 500 ms** before re-snapshotting.
- Dialogs (`rx.dialog.root`) mount lazily — the fields inside a "Create X" dialog do not exist in the snapshot until you click the trigger.
- Many pages set their own route via `@template(route="/...", ...)`; the route table below is the source of truth.

Conventions (same as the North-UI recipes):

- `S` is the session name (e.g. `fde-472`); `TRIAGE` is `.triage-artifacts-$S`.
- Refs are snapshot-local; re-snapshot after every state change.
- Prefer role / placeholder / name selectors when refs feel fragile.

## Preconditions

```sh
docker ps --format '{{.Names}}\t{{.Status}}' | grep -E 'northv.*admin'
# northv...-admin-1  Up ...
```

The admin service is separate from the main backend. If it is not up, `make dev` brings it up alongside everything else.

## Route map (verified against `apps/admin/admin/pages/`)

All routes are relative to `/admin/`.

| Route | Purpose |
|---|---|
| `/admin/` | dashboard / landing |
| `/admin/users` | users list and create/edit |
| `/admin/sso` | SSO connectors |
| `/admin/permissions` | groups, RBAC |
| `/admin/agents` | agent admin |
| `/admin/tools` | first-party tools + MCP servers |
| `/admin/models` | LLM provider/model configuration |
| `/admin/settings` | org-level settings |
| `/admin/experiments` | feature flags |
| `/admin/guardrails` | content guardrails |
| `/admin/flow_control` | rate limits / quotas |
| `/admin/analytics` | usage analytics |
| `/admin/audits` | audit log viewer |
| `/admin/automations` | automation admin |
| `/admin/workflows` | workflows (deprecated, but still present) |
| `/admin/whitelabel` | whitelabel / branding |
| `/admin/nfs-drives` | shared drive mounts |
| `/admin/terms-and-conditions` | ToS management |
| `/admin/troubleshoot` | troubleshoot tools |
| `/admin/status` | service status |

For anything not on this list, `rg 'route="/' apps/admin/admin/pages/` is the authoritative source.

---

## Recipe: Log into admin (local dev, static "System Admin" connector)

Local stacks ship a "System Admin" static OIDC connector that bypasses SSO.

```sh
playwright-cli -s=$S goto http://localhost:5001/admin/
sleep 2
playwright-cli -s=$S snapshot
# Landing shows one or more "Sign in with <connector>" buttons.
# In local dev, click the "System Admin" (or "local") button.
playwright-cli -s=$S click <system-admin-button-ref>
# This redirects to the backend /auth/login/local and then back to /admin/.
sleep 3
playwright-cli -s=$S snapshot
# You should now see the admin dashboard (sidebar with Users, Agents, etc.).
```

If the static connector button isn't visible, the admin is only offering real SSO connectors — in staging, ask the user to complete the SSO flow in the Playwright window (see [session-contract.md → SSO handoff](session-contract.md#sso-handoff)).

## Recipe: Create a user via Admin → Users

This is the only supported way to make a user who is tied to a specific org/role. Use it instead of raw SQL inserts whenever the bug involves org membership, roles, or Terms-of-Service state.

```sh
playwright-cli -s=$S goto http://localhost:5001/admin/users
sleep 2
playwright-cli -s=$S snapshot
# Look for a "Create User" button near the top-right of the users list.
playwright-cli -s=$S click <create-user-button-ref>
sleep 1
playwright-cli -s=$S snapshot
# The Create User dialog mounts. Fields (verified in users.py::create_user_form):
#   input name="given_name"     (placeholder "Jane")
#   input name="family_name"    (placeholder "Doe")
#   input name="email"          (placeholder "jane@example.com")
#   select for Role
#   input name="password"
#   input name="confirm_password"
#   button "Create User" (inside rx.dialog.close)
#   button "Cancel"
```

Because Reflex renders labels as sibling text, your best selectors are:

```sh
playwright-cli -s=$S fill "placeholder=Jane" "Mike"
playwright-cli -s=$S fill "placeholder=Doe" "Sharp"
playwright-cli -s=$S fill "placeholder=jane@example.com" "mike.sharp@example.com"
playwright-cli -s=$S fill "name=password" "password"
playwright-cli -s=$S fill "name=confirm_password" "password"
# Role picker: click it, then pick from the dropdown. Default is USER.
playwright-cli -s=$S click "role=button[name='Create User']"
sleep 2
playwright-cli -s=$S snapshot
# A green toast confirms creation; the user appears in the table.
```

Gotcha: the "Create User" **button inside the dialog** is wrapped in `rx.dialog.close`, so clicking it both submits the form *and* closes the dialog. If the dialog closes but the user does not appear, look for an error banner in the dialog before it closed — re-open via the Create User trigger to see the persisted error text.

## Recipe: Toggle a feature flag (Experiments)

```sh
playwright-cli -s=$S goto http://localhost:5001/admin/experiments
sleep 2
playwright-cli -s=$S snapshot
# A table of flags with a toggle switch per row, and org-scoped overrides.
# Find the flag by name, then toggle its switch.
playwright-cli -s=$S click <switch-ref-for-your-flag>
sleep 1
playwright-cli -s=$S snapshot
# Confirm the visual state flipped. No explicit save button; state persists
# on click via WebSocket round-trip.
```

Gotcha: client code caches feature flags. A freshly-toggled flag may not affect an open Playwright tab on the *end-user* app until you reload that tab.

## Recipe: Add a group (Permissions)

```sh
playwright-cli -s=$S goto http://localhost:5001/admin/permissions
sleep 2
playwright-cli -s=$S snapshot
# Look for "Add Group" (the button is spelled exactly that way —
# see apps/admin/admin/pages/permissions.py).
playwright-cli -s=$S click "role=button[name='Add Group']"
sleep 1
playwright-cli -s=$S snapshot
# Fill name, optional description, submit.
```

## Recipe: View audit entries for a user/org

```sh
playwright-cli -s=$S goto http://localhost:5001/admin/audits
sleep 2
playwright-cli -s=$S snapshot
# A filterable table. Filter inputs live at the top.
playwright-cli -s=$S fill "placeholder=Search by user" "<email-or-id>"
sleep 1
playwright-cli -s=$S snapshot
```

Use this before/after a repro to capture the authoritative server-side record of what happened.

## Recipe: Impersonate an end user for a repro

Admin does not expose a literal "impersonate" button. Two practical paths:

1. **Create a fresh throwaway user via the Create User recipe above, then log in as them in the North UI**. Fastest, keeps roles clean.
2. **Reset an existing user's password** (Users → edit a row → reset password), then log in as that user in the North UI. Only do this against local or developer-owned accounts.

Do not use SQL to change passwords — hashes are computed by the backend.

---

## Reflex-specific gotchas

- **Snapshots lag state changes.** Always `sleep 1` (or longer for network-bound state) before re-snapshotting.
- **Dialogs are lazy.** If you snapshot `/admin/users` before clicking "Create User", the form fields will not appear in the snapshot — they don't exist in the DOM yet.
- **Refs reshuffle on state updates.** Expect `e14` on one snapshot to become `e19` on the next after anything interactive. Prefer `role=`, `name=`, `placeholder=` selectors for clicks inside dialogs.
- **Toasts auto-dismiss.** Capture a screenshot within ~3 s of an action if the toast is your evidence.
- **WebSocket disconnects happen.** If the page goes unresponsive, reloading usually restores state. Save any in-progress form data first.

## Closing the session

Same as for the North UI:

```sh
playwright-cli -s=$S video-stop
playwright-cli -s=$S close
```

If the video only shows the login/connector-selection page, delete it — see the partial-video rule in [session-contract.md](session-contract.md#partial-video-contract).
