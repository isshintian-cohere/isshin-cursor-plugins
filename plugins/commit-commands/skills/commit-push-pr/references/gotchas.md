# Gotchas

Patterns that have broken the `commit-push-pr` skill in practice. Read before composing shell commands.

## Backticks in PR bodies

**Symptom:** A PR body on GitHub renders with literal `+ '` / `' +` fragments where inline code ticks (`` ` ``) were intended, and/or literal `\"` where double quotes were intended.

**Root cause:** Running `gh pr create --body "$(cat <<'EOF' ... EOF)"` looks safe because the HEREDOC delimiter is single-quoted (`<<'EOF'`), but the *outer* `"$(...)"` is double-quoted, so shell command substitution remains active. A bare backtick inside the HEREDOC is then parsed by the shell as *old-style* command substitution (`` `...` ``). Escaping that with `` \` `` works, but the common reflex is to "break up" the backticks using JavaScript template-literal style concatenation like `` ... ` + '`something`' + ` ... ``, which the shell happily passes through as literal characters. On top of that, `\"` inside such a HEREDOC doesn't unescape, so double quotes leak into the PR body as `\"`.

### Rule

Do not inline any non-trivial PR body through the shell at all. Specifically:

- Never use `gh pr create --body "..."` when the body contains backticks, code fences, `$(...)`, or `` ` `` characters.
- Never use `gh pr create --body "$(cat <<'EOF' ... EOF)"` for the same content. The outer `"..."` keeps command substitution active.

### Correct workflow

1. Write the PR body to a temporary markdown file, e.g. `/tmp/<issue>-pr-body.md`, using the `Write` tool (not `echo` / `cat >`). This avoids shell interpretation entirely.
2. Create or edit the PR with `--body-file`:
   ```bash
   gh pr create --title "..." --body-file /tmp/<issue>-pr-body.md
   gh pr edit <num> --body-file /tmp/<issue>-pr-body.md
   ```
3. Verify the rendered body:
   ```bash
   gh pr view <num> --json body -q .body | head -60
   ```
   Look for literal `\"`, `+ '`, or any sequence that differs from the source markdown.
4. Delete the temporary markdown file once the PR body is confirmed clean.

### Quick sanity checks before pushing a body to GitHub

- Does the source file contain any `\"`? It should contain plain `"`.
- Does the source file contain `' + '` or `` `' + `' `` artifacts? Those are template-literal leftovers; remove them.
- Does every inline-code span use a single pair of backticks and not a string-concatenation workaround?

## Commit messages with backticks

The same hazard applies to `git commit -m "$(cat <<'EOF' ... EOF)"` when the message contains backticks or `$(...)`. For multi-line commit messages with special characters, write the message to `/tmp/<issue>-commit-msg.txt` with the `Write` tool and use `git commit -F /tmp/<issue>-commit-msg.txt`, then delete the temp file.

## Forgetting to clean up

The temporary `/tmp/*-pr-body.md` / `/tmp/*-commit-msg.txt` files are cheap, but leaving them around pollutes `/tmp` and may leak customer context on a shared machine. After the PR URL is returned and verified, remove them:

```bash
rm -f /tmp/<issue>-pr-body.md /tmp/<issue>-commit-msg.txt
```
