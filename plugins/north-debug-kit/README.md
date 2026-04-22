# North Debug Kit

Cursor plugin that bundles North debugging skills for investigating and fixing bugs end-to-end: from a Linear ticket to a verified fix with browser evidence.

## Skills

The plugin ships four skills. `north-bug-triage` and `north-bug-fix` are the main orchestrators; `north-ui-driver` and `north-support-bundle` are capability skills they delegate to (and which you can also invoke standalone).

### `north-bug-triage`

Turns a Linear issue into a triage report that downstream implementers can act on.

The skill orchestrates:

1. Fetch Linear context (issue, comments, attachments, support bundles).
2. Explore the North codebase for the relevant code paths.
3. Reproduce the bug in a headed Playwright browser with video.
4. Analyze artifacts and support bundles when present.
5. Iteratively clarify with the user until the evidence is strong.
6. Emit `.triage-artifacts-{issue_id}/REPORT.md` with the smallest likely failing boundary, observables, next checks, and mitigations.

Use it whenever you start with a North FDE/BE/FE Linear ticket, a reproduction is needed, or a support bundle must be triaged.

### `north-bug-fix`

Inspired by [Ralph Loop](https://ghuntley.com/loop/). Takes an existing triage report and drives it to a verified fix (or a well-explained set of failed attempts).

The skill orchestrates:

1. Read the triage report and restate expected behavior.
2. Rank candidate fixes from highest to lowest confidence.
3. Implement each attempt in isolation.
4. Run minimal local validation, then validate user-visible behavior in a headed Playwright browser with video.
5. Stop on first verified success; record outcomes in `.triage-artifacts-{issue_id}/fix/FIX_REPORT.md`.

Use it only after `north-bug-triage` has produced a `REPORT.md`; otherwise the skill tells you to run triage first.

Mental model:
```
┌────────────────────────────────────────────────────────────────┐
│   north-bug-fix (parent agent)                                 │
│                                                                │
│   1. Rank fix proposals: [A, B, C]                             │
│   2. Task(best-of-n-runner) ─▶ worktree-A: implement fix A     │
│      └─ validate in shared headed browser ──▶ pass? stop.      │
│         fail? → discard worktree-A, keep failure notes         │
│   3. Task(best-of-n-runner) ─▶ worktree-B: implement fix B     │
│      └─ validate in shared headed browser ──▶ pass? stop.      │
│   4. ... (same for C)                                          │
└────────────────────────────────────────────────────────────────┘
```

### `north-ui-driver`

Drives the North end-user UI (`localhost:4000`) and Admin UI (`localhost:5001/admin/`) in a headed Playwright browser with video recording. Invoked by `north-bug-triage` for repro and by `north-bug-fix` for validation, but also usable on its own whenever you need UI evidence.

Ships canonical recipes for register/login, create-agent, sharing-picker, admin-login, and a session contract that enforces the partial-video and SSO-handoff rules.

### `north-support-bundle`

Identifies, downloads, and analyzes North support bundles, then maps their logs to the affected services (toolkit-backend, toolkit-frontend, inngest-server, task-runner, Atlas, Compass, Dex). Called from `north-bug-triage` when a bundle is attached, or standalone for bundle-only analysis.

## Typical Workflow

```
Linear issue ──▶ north-bug-triage ──▶ REPORT.md ──▶ north-bug-fix ──▶ FIX_REPORT.md
                       │                                  │
                       ▼                                  ▼
              north-ui-driver                   north-ui-driver
              north-support-bundle
```

Shared conventions across all four skills:

- Artifacts are written under `.triage-artifacts-{issue_id}/` in the current workspace.
- The headed Playwright browser is the source of truth for user-visible behavior.
- Local North services (`localhost:4000` for the UI, `localhost:5001/admin` for Admin UI) are the default targets; overrides live in each skill's `config.json`.
- Scripts bundled with the plugin are invoked from their synced location at `$HOME/.cursor/plugins/local/north-debug-kit/skills/<skill>/scripts/...` (see [sync-local-plugins.sh](../../scripts/sync-local-plugins.sh)).

## Prerequisites and peer skills

Runtime prerequisites and peer skills required by this plugin live in the [repo README](../../README.md#plugin-prerequisites-and-peer-dependencies) alongside every other plugin's requirements.
