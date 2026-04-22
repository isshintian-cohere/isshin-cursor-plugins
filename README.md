# Cursor FDE Team Marketplace

Build and publish Cursor Marketplace plugins for FDE team from a single repo. The repo already contains a few useful plugins:

- `commit-commands`: Facilitate git commits, cleaning up stale local branches with merged upstream, and e2e commit push and then create a draft PR using North's git PR template.
- `north-debug-kit`: North debugging skills for triage, Playwright reproduction, support bundle analysis, and end-to-end fix validation
- `learning-output-style`: Interactive learning mode via a `sessionStart` hook (extra session instructions; optional).

## Prerequisites

Some plugins need external tools or skills that are not bundled in the plugins. Install them alongside the plugin they apply to.

### `north-debug-kit`

**Runtime dependencies**

- The North stack running locally (`localhost:4000` for the UI, `localhost:5001/admin/` for Admin UI), or staging access.

**External tools/skills to install separately**

- Python 3 on `PATH` for `north-bug-triage/scripts/fetch_linear_context.py`.
- `ffmpeg` on `PATH` (or reachable via `npx playwright install ffmpeg`) for video capture.
- `playwright-cli` available globally or via `npx` — `north-ui-driver`'s `start_session.sh` auto-detects which.
- `linear-cli` used to fetch/refresh Linear issue data and list/download attachments. Without it, you can still run triage by supplying Linear context manually or via Linear MCP, but `scripts/fetch_linear_context.sh` will fail. (Install both CLI and the skill following [the guide](https://github.com/schpet/linear-cli))

### `commit-commands`
- GitHub CLI `gh` + `git`

## Getting started

To install plugins locally in Cursor, sync them into `~/.cursor/plugins/local` with the helper script:

```bash
chmod +x scripts/sync-local-plugins.sh
./scripts/sync-local-plugins.sh install
```

Selected plugins are copied into `~/.cursor/plugins/local`, overwriting any existing local copies with the same name.

To remove locally installed plugins listed in this repo, run:

```bash
./scripts/sync-local-plugins.sh uninstall
```

## Single plugin vs multi-plugin

This template defaults to **multi-plugin** (multiple plugins in one repo).

For a **single plugin**, move your plugin folder contents to the repository root, keep one `.cursor-plugin/plugin.json`, and remove `.cursor-plugin/marketplace.json`.

## Submission checklist

- Each plugin has a valid `.cursor-plugin/plugin.json`.
- Plugin names are unique, lowercase, and kebab-case.
- `.cursor-plugin/marketplace.json` entries map to real plugin folders.
- All frontmatter metadata is present in rule, skill, agent, and command files.
- Logos are committed and referenced with relative paths.
- `node scripts/validate-template.mjs` passes.
- Repository link is ready for submission to the Cursor team (Slack or `kniparko@anysphere.com`).
