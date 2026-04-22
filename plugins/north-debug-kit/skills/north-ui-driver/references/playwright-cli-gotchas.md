# playwright-cli Gotchas

Tool-level quirks and recovery patterns for `playwright-cli` as observed driving the North UI and Admin UI. These apply to *any* skill that uses `playwright-cli` — keep the scope narrow to the tool itself, not to North-specific flows. For those, see [north-ui-recipes.md](north-ui-recipes.md) and [admin-ui-recipes.md](admin-ui-recipes.md).

## Command-name quirks

- Use `goto <url>`, not `navigate`. There is no `navigate` command.
- Use `screenshot --filename=<name>`, **not** a positional path. A positional argument is interpreted as a CSS selector for the element to screenshot and will throw `Unexpected token "" while parsing css selector ""`.
  ```sh
  # Wrong:
  playwright-cli -s=$S screenshot /tmp/out.png
  # Right:
  cd /tmp && playwright-cli -s=$S screenshot --filename=out.png
  ```
  Files always land in the current working directory; `cd` first if you care about where they go.
- `playwright-cli --help` lists the full command set. When a command name feels wrong, check help first rather than guessing.

## Starting a session

- Always pass `--headed` for evidence-capture sessions. Headless runs do not record usable videos and are harder for a human reviewer to audit.
- Verify the session landed headed by running `playwright-cli list` and confirming `headed: true` in the entry for your session name. The helper `scripts/start_session.sh` already does this verification.
- The `open` command accepts a URL positionally. If you omit it, `open` still succeeds but the session has no page to act on and most subsequent commands fail in unhelpful ways. Pass at least `about:blank` if you genuinely have no URL yet.

## Profile reuse TypeError

Symptom:

```
### Browser `<session>` opened with pid <n>.
### Error
TypeError: Cannot read properties of undefined (reading 'url')
```

…after which `list` shows the session as `closed` within a second.

Known cause: an existing `--profile=<dir>` that contains state from a previous run (most often after an aborted close). The fix:

```sh
playwright-cli -s=$S close 2>/dev/null || true
rm -rf "$TRIAGE/profile"
mkdir -p "$TRIAGE/profile"
bash "$HOME/.cursor/plugins/local/north-debug-kit/skills/north-ui-driver/scripts/start_session.sh" $S <url> $TRIAGE
```

Do not try to patch the profile by hand — it is a Chromium user-data-dir, and Chromium is finicky about which fields it rewrites on open. Deleting and recreating is safe for these sessions, which have no data worth keeping.

## Video recording

- `video-start <path>` must be called *after* the session is open and healthy.
- If it errors with anything containing `ffmpeg`, install it once:
  ```sh
  npx playwright install ffmpeg
  ```
  Then retry `video-start`. `scripts/start_session.sh` already handles this fallback.
- `video-stop` returns the written `.webm` path. Capture it in the calling skill's report under the *Reproduction* section.
- If the session ends without a `video-stop`, Playwright may finalize the video on close, but do not rely on it — stop explicitly.

## Ref staleness

Refs printed by `snapshot` (e.g. `e14`, `e223`) are **per-snapshot identifiers**, not DOM ids. They are invalidated by any of:

- navigation (`goto`, link click, `/register` → `/onboarding`)
- modal / popover open or close
- React re-render caused by typing, focus, or streamed content
- WebSocket-driven state updates in Reflex (any click on an interactive admin component)

If a command fails with "No element with ref X" or acts on the wrong element, re-snapshot and try again. If refs keep shifting, switch to stable selectors:

```sh
playwright-cli -s=$S click "role=button[name='Create agent']"
playwright-cli -s=$S fill "placeholder=Search by email to add people" "mike.sharp"
playwright-cli -s=$S click "role=link[name='Settings']"
# Form inputs with name attributes (Reflex admin):
playwright-cli -s=$S fill "name=email" "mike.sharp@example.com"
```

`playwright-cli` already prints codegen-style selectors below each command it runs (e.g. `await page.getByPlaceholder('Search by email to add people').fill(...)`); those are the selectors to reuse when refs go stale.

## Tabs

- `tab-new [url]` opens a new tab; subsequent commands target the *active* tab. Use `tab-list` and `tab-select <index>` to switch.
- Some SSO flows open a popup; after completing SSO, close the popup explicitly with `tab-close` before continuing, or `snapshot` may still target the popup.

## Storage state / cookies

- `state-save` and `state-load` work across sessions using the same profile dir. Useful if you want to log in once and reuse auth for multiple repros — but remember a saved state can also carry a stale feature-flag cache.
- Do not hand-edit cookies to impersonate users; sessions rely on server-issued refresh tokens. Use the proper auth recipe instead (see [session-contract.md → SSO handoff](session-contract.md#sso-handoff)).

## When `snapshot` output looks truncated

`snapshot` writes the full snapshot to `.playwright-cli/page-<timestamp>.yml` and prints an abbreviated version inline. If the inline view is cut off, read the file directly:

```sh
ls -t .playwright-cli/page-*.yml | head -1
```

This is especially useful when hunting for a component deep in the DOM (e.g. a lazy dialog, or the full list of sidebar routes).

## Error taxonomy (quick reference)

| Error fragment | Likely cause | Fast fix |
|---|---|---|
| `Cannot read properties of undefined (reading 'url')` | profile reuse bug | delete `--profile` dir, reopen |
| `Unexpected token "" while parsing css selector ""` | passed positional path to a command that takes a selector | use `--filename=` or a quoted selector |
| `No element with ref ...` | snapshot went stale | re-snapshot, then reissue |
| `Expected a headed Playwright session` | `scripts/start_session.sh` verification failed | check `playwright-cli list`; often fixed by a clean `close` + re-open |
| `ffmpeg` in error text | ffmpeg missing | `npx playwright install ffmpeg` |
| session status flips to `closed` right after `open` | profile bug **or** another process holding the profile | check for stray Chrome processes; `rm -rf` profile; reopen |
| `Target page, context or browser has been closed` | acting on a session after `close` / crash | reopen via `scripts/start_session.sh` |

## When in doubt, re-snapshot and screenshot

If a recipe seems to succeed but the page isn't doing what you expect:

```sh
playwright-cli -s=$S snapshot
playwright-cli -s=$S screenshot --filename=debug-$(date +%H%M%S).png
```

Most "mystery" failures resolve to either a stale ref or an unexpected modal. Both are visible in a fresh snapshot and screenshot, and both take under three seconds to capture.
