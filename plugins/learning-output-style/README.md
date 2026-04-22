# Learning Output Style

This plugin is adapted from [Boris Cherny's original plugin](https://github.com/anthropics/claude-code/tree/main/plugins/learning-output-style). It adds a native Cursor `sessionStart` hook that enables an interactive learning mode with brief educational explanations.

Warning: this plugin adds extra session instructions, so only enable it if you want the additional token cost and the more hands-on workflow.

## What It Does

When enabled, Cursor is encouraged to:

1. Ask you for 5-10 lines of meaningful code at decision points.
2. Focus your contributions on business logic, design choices, and implementation trade-offs.
3. Prepare the surrounding context before asking for input.
4. Provide short educational insights before and after implementation work.

## When Cursor Should Ask For Contributions

Cursor should ask you to write code for:

- Business logic with multiple valid approaches
- Error handling strategies
- Algorithm implementation choices
- Data structure decisions
- User experience decisions
- Design patterns and architecture choices

## When Cursor Should Implement Directly

Cursor should avoid turning trivial work into homework. It should implement directly when the task is mostly:

- Boilerplate or repetitive code
- Obvious implementations with no meaningful choices
- Configuration or setup code
- Simple CRUD operations

## Example Interaction

**Assistant:** I've set up the authentication middleware. The session timeout behavior is a security vs. UX trade-off - should sessions auto-extend on activity, or have a hard timeout?

In `auth/middleware.ts`, implement the `handleSessionTimeout()` function to define the timeout behavior.

Consider: auto-extending improves UX but may leave sessions open longer; hard timeouts are more secure but might frustrate active users.

**You:** Write 5-10 lines implementing your preferred approach.

## Educational Insights

In addition to interactive learning, the plugin asks Cursor to provide short implementation insights in this format:

```
`★ Insight ─────────────────────────────────────`
[2-3 key educational points about the codebase or implementation]
`─────────────────────────────────────────────────`
```

These insights should stay specific to the codebase and the change being discussed, rather than turning into generic programming lectures.

## How It Works

The plugin registers a native Cursor `sessionStart` hook in `hooks/hooks.json`. That hook runs `scripts/session-start.sh`, which injects additional context into each new agent conversation.

## Usage

Once installed, the plugin activates automatically at the start of each Cursor agent session. No extra configuration is required.

## Philosophy

Learning by doing is more effective than passive observation. This plugin shifts the interaction from "watch and learn" to "build and understand" by asking for small, meaningful contributions where your choices materially affect the result.
