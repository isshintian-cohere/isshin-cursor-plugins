# North UI Recipes (end-user web app)

Copy-paste playwright-cli recipes for the North end-user web app (Next.js at `http://localhost:4000` locally, `https://stg.demo.cloud.cohere.com/` on staging). For admin flows, see `admin-ui-recipes.md`. For tool-level quirks (e.g. the `screenshot --filename=` flag), see `playwright-cli-gotchas.md`. For auth/data strategy, see `repro-strategy.md`.

Conventions used in every recipe:

- `S` is the session name — typically the Linear issue id (lowercase), e.g. `fde-472`. Export it once per session: `export S=fde-472`.
- `TRIAGE` is the triage folder: `export TRIAGE=.triage-artifacts-$S`.
- Refs like `e14` come from `playwright-cli -s=$S snapshot`. **Refs are not stable across navigations, modals, or React re-renders** — always re-snapshot before using one. See `playwright-cli-gotchas.md`.
- When a ref is fragile, prefer a role/placeholder selector (what `playwright-cli` itself prints in its codegen-like output, e.g. `getByPlaceholder('Search by email to add people')`).

## Preconditions

```sh
docker ps --format '{{.Names}}\t{{.Status}}' | grep -E 'northv.*-(backend|frontend|db)'
# All three should say "Up".
```

If nothing is up, the user has to bring the stack up — don't do it unannounced. `make dev` is the canonical command.

## Start a recording session

The skill already ships `scripts/start_repro.sh`; prefer it over hand-rolling:

```sh
bash "$(dirname "$SKILL_DIR")/scripts/start_repro.sh" $S http://localhost:4000/login $TRIAGE
```

The script creates `$TRIAGE/profile`, opens a headed Chrome with that profile, starts the video, and prints a resume-hint. If `open` emits `TypeError: Cannot read properties of undefined (reading 'url')`, it is the stale-profile bug — see `playwright-cli-gotchas.md` → "Profile reuse TypeError".

## Route map (verified against `js/apps/assistants_web/src/app/`)

| Route | Purpose |
|---|---|
| `/login` | sign in (SSO on staging, password locally) |
| `/register` | password sign-up (local dev only, unless the tenant enables it) |
| `/onboarding` | first-time onboarding — always has a "Skip" button |
| `/` | Home, including the first-time product tour |
| `/agents` | agent browser |
| `/agents/new` | create-agent form (Basics / Tools / Access) |
| `/chat` | start a new chat |
| `/chat/[agentId]` | chat with a specific agent |
| `/chat/[agentId]/c/[conversationId]` | specific conversation |
| `/docs` / `/docs/[agentId]` | document mode |
| `/settings` | user settings; use `?tab=tools` for tool connections |
| `/drive` | My Drive file storage |
| `/tables` | Tables |
| `/workflows` | deprecated — use Automations |
| `/automations` | Automations |
| `/automations-builder` / `/automations-builder/[id]` | low-code builder |
| `/developer` / `/developer/[tab]` | developer tools (MCP, API tokens, etc.) |
| `/share/[id]` | shared-conversation view |

For anything not on this list, run `rg -l "page.tsx" js/apps/assistants_web/src/app/` rather than guessing.

---

## Recipe: Register a throwaway user (local password auth)

Use when you need any logged-in actor. Works only on a local stack that has password sign-up enabled.

```sh
playwright-cli -s=$S goto http://localhost:4000/register
sleep 1
playwright-cli -s=$S snapshot
# Expected anchors on /register:
#   textbox "First name"           [ref=e14]
#   textbox "Last name"            [ref=e17]
#   textbox "Preferred name (...)" [ref=e20]
#   textbox "Email"                [ref=e23]
#   textbox "Password"             [ref=e26]
#   textbox "Confirm password"     [ref=e29]
#   button  "Create account"       [ref=e34]
```

Then (substitute the refs you actually see):

```sh
playwright-cli -s=$S fill e14 "Test"
playwright-cli -s=$S fill e17 "Sharer"
playwright-cli -s=$S fill e23 "test.sharer@example.com"
playwright-cli -s=$S fill e26 "password"
playwright-cli -s=$S fill e29 "password"
playwright-cli -s=$S click e34
# Lands on /onboarding (takes ~10s).
```

Convention: throwaway accounts in UI recipes always use `password` as the password for simplicity (the local stack is expected to have the default password policy disabled).

If `/register` 404s, password auth is disabled for this tenant — use SSO instead.

## Recipe: Skip onboarding and the home-page tour

This happens after any fresh registration and before you can reach most pages.

```sh
playwright-cli -s=$S snapshot
# On /onboarding: button "Skip" [ref=e87] and "Get started" [ref=e88]. Either works.
playwright-cli -s=$S click <skip-or-get-started-ref>
sleep 2
playwright-cli -s=$S snapshot
# On / : product tour overlay. button "Skip tour" [ref≈e170].
playwright-cli -s=$S click <skip-tour-ref>
```

Both screens re-mount refs, so re-snapshot between them. If you skip either, you can still click "Skip tour" later from the tour overlay.

## Recipe: Land on the login page as an anonymous visitor

Sometimes you want the login screen clean (no cookies). The cleanest way is a fresh profile:

```sh
rm -rf $TRIAGE/profile
bash "$(dirname "$SKILL_DIR")/scripts/start_repro.sh" $S http://localhost:4000/login $TRIAGE
```

Do not edit cookies by hand — the app expects a full auth round-trip.

## Recipe: Create an agent via `/agents/new`

Preconditions: logged-in user, onboarding skipped.

```sh
playwright-cli -s=$S goto http://localhost:4000/agents/new
sleep 3
playwright-cli -s=$S snapshot
# The form has three logical sections in the sidebar: Basics, Tools, Access.
# Top-level anchors:
#   textbox "Name"        (Basics)
#   textbox "Description" (Basics)
#   combobox "Model"      (Basics)
#   radiogroup with "Private" / "Public" / "Limited" (Access)
#   button "Create agent" [disabled until name is set]
```

Fill Basics (refs vary):

```sh
playwright-cli -s=$S fill <name-ref> "Triage Test Agent"
playwright-cli -s=$S fill <description-ref> "Created by the north-bug-triage skill."
# Optional: open the Access section if it isn't expanded, by clicking its sidebar link.
playwright-cli -s=$S click <create-agent-button-ref>
# Lands on /chat/<new-agent-id>.
```

## Recipe: Reach the sharing/"People with access" picker

This is the surface exercised by `FDE-472`. From `/agents/new` (Access section is visible by default) or from an existing agent's Settings → Access.

```sh
playwright-cli -s=$S snapshot
# In the "Set access permissions" card:
#   radio "Private"   (default)
#   radio "Limited"   [disabled until you choose it]
#   combobox          <-- the search input
#   placeholder is the string "Search by email to add people"
# The result popover only renders when there are matches — empty results hide the popover.
playwright-cli -s=$S fill <combobox-ref> "mike.sharp"
sleep 2
playwright-cli -s=$S snapshot
# Expect a dialog [ref=...] with listbox "Suggestions" and option "<fullname> <email>".
```

Gotcha: the placeholder copy ("Search by email to add people") is literal truth — the backend only matches email prefixes. If you're investigating a search bug, capture both a hit (`mike.sharp`) and a miss (`MIKE SHARP`, `Sharp`) as screenshots.

## Recipe: Start a new chat with a specific agent

```sh
playwright-cli -s=$S goto http://localhost:4000/chat/<agentId>
sleep 3
playwright-cli -s=$S snapshot
# textbox "Message <agent-name>" is the composer.
playwright-cli -s=$S fill <composer-ref> "Hello, please respond."
playwright-cli -s=$S press Enter
# Watch for streaming text in the message list.
```

For generic chat (no specific agent), use `/chat` instead — the URL updates once a conversation is created.

## Recipe: Open Settings → Tools

```sh
playwright-cli -s=$S goto http://localhost:4000/settings?tab=tools
sleep 2
playwright-cli -s=$S snapshot
# Lists tools with Connect / Disconnect buttons, grouped by provider.
```

To deep-link into a specific tool configuration panel, append `&tool=<tool_id>` (e.g. `?tab=tools&tool=google_drive`). Tool IDs live in `src/backend/tools/**/tool.py` next to the `BaseTool` subclass.

## Recipe: Upload a file to My Drive

```sh
playwright-cli -s=$S goto http://localhost:4000/drive
sleep 2
playwright-cli -s=$S snapshot
# button "Upload" or a drop-zone is visible near the top.
playwright-cli -s=$S click <upload-button-ref>
playwright-cli -s=$S upload /path/to/local/file.pdf
sleep 3
playwright-cli -s=$S snapshot
# The file appears in the listing; processing is async — give it a few seconds.
```

## Recipe: Log out

```sh
playwright-cli -s=$S goto http://localhost:4000/logout
# Lands back on /login.
```

Cleaner than manually clearing cookies if you want to switch users in the same session.

---

## Screenshot / video capture tips

Two failure-mode screenshots are more valuable than a 30-second video, because they are zero-friction for reviewers to open.

```sh
cd $TRIAGE
playwright-cli -s=$S screenshot --filename=ui-success-<label>.png
playwright-cli -s=$S screenshot --filename=ui-fail-<label>.png
```

Note the `--filename=` flag — positional paths do not work. See `playwright-cli-gotchas.md`.

Stop recording and close when done:

```sh
playwright-cli -s=$S video-stop
playwright-cli -s=$S close
```

If the resulting video only shows the login page, delete it — see the partial-video rule in `repro-strategy.md`.

## When refs break mid-flow

If a recipe stops working halfway — e.g. a `click <ref>` fails with "No element with ref X" — something in the page state invalidated the snapshot (navigation, modal open/close, streaming update). Re-snapshot and continue. If that still fails, use a stable selector:

```sh
playwright-cli -s=$S click "role=button[name='Create agent']"
playwright-cli -s=$S fill "placeholder=Search by email to add people" "mike.sharp"
```

Reflex-style admin components need different treatment — see `admin-ui-recipes.md`.
