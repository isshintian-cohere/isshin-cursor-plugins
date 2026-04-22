# Worked Example

## Automation Regression Triage

Input:

- Linear issue `FDE-514`
- staging URL for the Automations page
- support bundle from a `1.8.x` deployment
- symptom: existing automations fail after upgrade

Explore first:

- `linear-cli` showed a regression-style issue, not a vague reliability complaint.
- The title and description said old automations were causing failures in new automation features.
- Comments pointed to a support bundle attachment, but the bundle was not read yet.
- Code exploration focused on the smallest likely path first:
  - frontend automations surface
  - backend automation entrypoint
  - async workflow path in `inngest-server` and `toolkit-task-runner`
- That code read established a likely service chain before reproduction:
  - `toolkit-frontend` -> `toolkit-backend` -> `inngest-server` -> `toolkit-task-runner`

Reproduce second:

- A headed Playwright browser session was opened and recorded end to end.
- The repro was simple: open Automations, run an existing automation, observe failure.
- The browser video captured the user flow for later human review.
- Browser evidence showed the UI reached the expected execution path and the failure happened after kickoff, not during initial page rendering.

Triage artifacts third:

- `helm/*.json` showed the deployed app version and Inngest wiring.
- `inngest-server` logs showed repeated `app/automations/workflow` events followed by repeated edge `500` failures.
- `toolkit-task-runner` logs confirmed automation functions were registered and enabled.
- `toolkit-backend` logs showed automation-related settings and at least one healthy internal chat request.
- `toolkit-frontend` logs mostly showed failed trace forwarding, which did not match the user-facing symptom.

Best interpretation:

- The strongest failing boundary was `Inngest -> task-runner` for automation workflow execution.
- The bundle showed the symptom clearly, but not the exact root-cause traceback for the failing execution window.
- The most useful next step was to pull task-runner or backend logs for the same `execution_id` or timestamp window, or inspect the matching code path for automation workflow execution and back-compat handling.

Example summary:

```markdown
## Summary
The issue looks like an automation execution regression rather than a general frontend outage. Linear context, code exploration, browser reproduction, and artifact evidence all point to a downstream async workflow failure after the UI successfully kicks off execution.

## Strongest Observables
- Linear issue says existing automations fail after upgrade.
- Code exploration mapped the affected flow to the async automation execution path before any log reading.
- Headed Playwright repro reached the failure reliably and produced a video plus browser-side evidence.
- Inngest logs show `app/automations/workflow` followed by repeated edge `500` errors.
- Task-runner logs show automations are registered and the recovery job is healthy in the captured window.
- Frontend logs mostly contain trace-export noise.

## Likely Failing Boundary
- `toolkit-backend` -> `inngest-server` -> `toolkit-task-runner`, most likely in the workflow execution path rather than the initial UI action.

## Immediate Mitigation
- Route affected users away from legacy automation paths if possible, or disable the specific failing workflow shape behind a feature flag while investigating.

## Long-Term Fixes
- Inspect the automation workflow code path for upgrade or back-compat assumptions around legacy automation shapes.
- Add regression coverage for pre-upgrade automation data flowing through the current execution path.

## Gaps
- The support bundle does not include the exact traceback for the failing execution window.
- The issue report does not yet identify a specific legacy automation shape or schema mismatch.

## Next Checks
- Correlate the failing `execution_id` across task-runner and backend logs outside the captured window.
- Inspect the automation workflow code path for upgrade or back-compat assumptions.
```

## What Made This Triage Effective

- The Linear issue gave a crisp repro and routed the initial code exploration.
- The headed Playwright repro produced a human-reviewable video and narrowed the failing boundary before artifact analysis.
- The bundle scan established deployed version and service topology after the code and browser context were already clear.
- The final output separated proven observations from still-unproven root cause and proposed immediate mitigation plus long-term fixes.

---

## Full Loop: Triage → Fix → Verify

Continuing the example above, here's how a complete triage-to-verification loop looks:

### Fix Implementation

Based on the triage findings, the implementation agent:

1. Identified the back-compat issue in `src/backend/services/inngest/automations/workflow.py`
2. Added schema migration handling for legacy automation shapes
3. Added a regression test in `src/backend/tests/vcr/automations/test_legacy_compat.py`

### Verification Repro

After the fix was deployed to staging, using the `north-ui-driver` skill:

```bash
# Start a new repro session in the same triage folder
bash "$HOME/.cursor/plugins/local/north-debug-kit/skills/north-ui-driver/scripts/start_session.sh" \
  verify https://stg.demo.cloud.cohere.com/automations .triage-artifacts-fde-514/playwright

# Artifacts saved to:
# - .triage-artifacts-fde-514/playwright/verify-20240115-143022.webm
# - .triage-artifacts-fde-514/playwright/profile/
```

The verification video showed:

1. Opened Automations page
2. Selected the same legacy automation that previously failed
3. Triggered execution
4. Execution completed successfully (green checkmark in UI)
5. Execution history showed the run with no errors

### Verification Summary

```markdown
## Verification Result: PASSED

- Issue: FDE-514
- Fix commit: abc123
- Verification video: `.triage-artifacts/repro-verify-fde514/verify-fde514-20240115-143022.webm`

## Evidence
- Legacy automation that previously failed now executes successfully
- No 500 errors in network tab during execution
- Execution history shows completed run
- Inngest dashboard shows successful function invocation

## Remaining Work
- [ ] Merge PR after review
- [ ] Monitor prod deployment for similar errors
- [ ] Close Linear issue with verification link
```

### Artifacts Produced

All artifacts live in a single folder named after the Linear issue:

```
.triage-artifacts-fde-514/
├── REPORT.md                           # Final triage report
├── linear-context.md
├── playwright/
│   ├── stg-bug-20240115-100512.webm    # Initial failure repro
│   ├── verify-20240115-143022.webm     # Verification pass
│   └── profile/
└── bundles/
    └── support-bundle-20240115.tar.gz  # Downloaded support bundle
```

This complete loop ensures:
- The fix actually resolves the user-visible symptom
- Video evidence exists for both failure and fix states
- All artifacts are organized under a single issue-specific folder
- The final report is easy to find and hand off
- The Linear issue can be closed with concrete verification
