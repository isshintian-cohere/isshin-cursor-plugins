---
name: commit-push-pr
description: Commit the current changes, push the branch, and open a pull request.
---

# Commit, push, and open a PR

Complete the full git workflow for the current worktree.

## Steps

1. Inspect the current git status, staged and unstaged diff, branch tracking state, recent commits, and the branch diff from its base branch.
2. Create a new branch if needed before committing.
3. Stage the relevant files and create a single commit with a message that matches the repository's style.
4. Push the current branch to `origin`, setting upstream if needed.
5. Create a **draft** pull request (`gh pr create --draft`) using [references/pull_request_template.md](references/pull_request_template.md).

## Guardrails

- Never force push.
- Never change git config.
- Do not amend unless the user explicitly asked for it.
- Do not include likely secrets in the commit.
- If there is nothing new to commit, continue with push and PR creation only if the branch already contains the intended changes.
- Never inline a PR body or commit message through a shell HEREDOC when it contains backticks, code fences, or `$(...)` — the outer `"..."` around `$(cat <<'EOF' ...)` keeps command substitution active and mangles the content. Instead, write the body to a temp file with the `Write` tool, pass it via `gh pr create --body-file` (or `git commit -F`), then remove the temp file.
