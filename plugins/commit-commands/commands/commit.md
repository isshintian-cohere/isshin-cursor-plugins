---
name: commit
description: Analyze the current git changes and create a single commit.
---

# Create a commit

Create one git commit for the current repository changes.

## Steps

1. Inspect the current git status, staged and unstaged diff, and recent commit messages so the new commit matches the repository's style.
2. Stage the relevant files for this change, but do not include likely secrets such as `.env` files or credential dumps.
3. Create a single commit with a concise message that explains why the change exists.
4. Verify the result with `git status`.

## Guardrails

- Do not change git config.
- Do not create an empty commit.
- Do not amend unless the user explicitly asked for it.
- Respect repository hooks and stop if they reject the commit.
