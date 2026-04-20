# FDE North Skills

Cursor plugin that bundles FDE agent skills for investigating and fixing North bugs end-to-end: from a Linear ticket to a verified fix with browser evidence.

## Skills

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

Takes an existing triage report and drives it to a verified fix (or a well-explained set of failed attempts).

The skill orchestrates:

1. Read the triage report and restate expected behavior.
2. Rank candidate fixes from highest to lowest confidence.
3. Implement each attempt in isolation.
4. Run minimal local validation, then validate user-visible behavior in a headed Playwright browser with video.
5. Stop on first verified success; record outcomes in `.triage-artifacts-{issue_id}/fix/FIX_REPORT.md`.

Use it only after `north-bug-triage` has produced a `REPORT.md`; otherwise the skill tells you to run triage first.

## Typical Workflow

```
Linear issue ──▶ north-bug-triage ──▶ REPORT.md ──▶ north-bug-fix ──▶ FIX_REPORT.md
```

Both skills share conventions:

- Artifacts are written under `.triage-artifacts-{issue_id}/` in the current workspace.
- The headed Playwright browser is the source of truth for user-visible behavior.
- Local North services (`localhost:4000` for the UI, `localhost:5001/admin` for Admin UI) are the default targets; overrides live in each skill's `config.json`.

## Prerequisites

- Linear API access configured for the `linear-cli` skill (triage only).
- Playwright CLI installed and the North stack running locally.
- `ffmpeg` on `PATH` for video capture.

## Layout

```
fde-north-skills/
├── .cursor-plugin/plugin.json
├── README.md
└── skills/
    ├── north-bug-triage/
    │   ├── SKILL.md
    │   ├── config.json
    │   ├── references/         # checklist, recipes, artifact guide, templates
    │   └── scripts/            # fetch_linear_context.{py,sh}, start_repro.sh
    └── north-bug-fix/
        ├── SKILL.md
        ├── config.json
        ├── references/         # checklist, examples, fix-report-template
        └── scripts/            # start_validation.sh
```
