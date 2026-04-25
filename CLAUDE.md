# Working preferences

## Important files
- SPEC.md - specification / Technical Requirements Document, keep it in sync with code changes
- CLAUDE.md - personal Ivan's preferences of using Claude Code, suggest updates based on coding sessions in Claude
- TODO.md - informal list of changes to be done, bugs, new features etc, update it when implementing todo tasks from this file

## Branch & workflow
- Always operate in the top-level repo directory (`/Users/Shared/git/github.com/pomodoro/`). Never `cd` into or edit files under `.claude/worktrees/*`. If the harness has placed you inside a worktree, switch to the main repo dir before doing any work.
- Prefer working directly on `main`. Use a feature branch only when explicitly asked.
- Ivan tests locally in Xcode on his iPhone before deciding to keep or revert.

## Pull requests
- Do not create PRs by default. Only create one when explicitly asked.

## Commits
- Don't auto-commit. Make the change, then wait for Ivan to review before committing.
- When Ivan asks to commit, stage only what's under review; don't batch unrelated changes.
- Don't `git push` unless explicitly asked.

## File and git access
- Read and edit any file in the project, even untracked or unstaged ones, without asking.
- Run any `git` or `gh` command without asking. Still confirm before destructive operations (`push --force`, `reset --hard`, `branch -D`, etc.).
- Run any standard CLI commands (`find`, `ls`, `mv`, `cp`, `grep`, `rm`, etc.) without asking.

## Code style
- SwiftUI + SwiftData, iOS 17+, MVVM architecture.
- No unnecessary comments. Only add a comment when the *why* is non-obvious.
- Don't add features, abstractions, or error handling beyond what the task requires.

## Communication
- Keep responses short and to the point.
- When referencing code, include file path and line number so Ivan can navigate directly.
- No emojis unless asked.
