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
5. Create a pull request using [references/pull_request_template.md](references/pull_request_template.md). Make sure to fill out "Description of the PR" at the top and "AI Description".
   - Write the PR body to a temporary markdown file first (e.g. `/tmp/<issue>-pr-body.md`) and pass it via `gh pr create --body-file`. Never inline the body through a shell HEREDOC. See [references/gotchas.md](references/gotchas.md#backticks-in-pr-bodies).
   - After the PR is created or edited, verify the body rendered correctly with `gh pr view <num> --json body -q .body` and remove the temporary file.

## Guardrails

- Never force push.
- Never change git config.
- Do not amend unless the user explicitly asked for it.
- Do not include likely secrets in the commit.
- If there is nothing new to commit, continue with push and PR creation only if the branch already contains the intended changes.
- Never use `gh pr create --body "..."` or `gh pr create --body "$(cat <<EOF ...)"` for any body that contains backticks, code fences, or `$(...)` substrings. Always write the body to a markdown file and use `--body-file`. See [references/gotchas.md](references/gotchas.md).
