# Commit Commands

This plugin is based on Claude Code's `commit-commands` plugin, adapted to Cursor's plugin format and conventions with minor North-specific tweaks. It contains three skills for common git workflows so you can stay in the chat instead of manually stitching together git and GitHub CLI commands.

## Commands

### `/commit`

Analyzes the current working tree, stages relevant files, and creates a single commit that matches the repository's existing message style.

### `/commit-push-pr`

Handles the full branch workflow:

1. Create a branch if needed
2. Commit the current work
3. Push to `origin`
4. Open a draft pull request based on the [North PR template](skills/commit-push-pr/references/pull_request_template.md).

### `/clean_gone`

Finds local branches marked `[gone]`, removes any associated worktrees, and deletes the stale branches.

## Notes

- The command names match the original Claude Code plugin, including `/clean_gone`.
- `/commit-push-pr` expects `gh` to be installed and authenticated.
- The commands rely on Cursor's normal tool permissions and repository safety rules.
