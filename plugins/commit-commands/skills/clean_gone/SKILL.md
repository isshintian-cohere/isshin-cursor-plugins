---
name: clean_gone
description: Remove local branches and worktrees whose remote branches are gone.
---

# Clean gone branches

Clean up local branches whose remote tracking branches no longer exist.

## Steps

1. Inspect local branches and worktrees to find branches marked `[gone]`.
2. For each such branch, remove any associated worktree before deleting the local branch.
3. Delete all matching local branches.
4. Report which worktrees and branches were removed, or say that no cleanup was needed.

## Guardrails

- Do not touch the current branch.
- Only remove branches explicitly marked `[gone]`.
- Prefer safe inspection before deletion.
- If a branch cannot be removed cleanly, report the blocker instead of guessing.
