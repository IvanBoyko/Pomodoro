# Working preferences

## Important files
- SPEC.md - specification / Technical Requirements Document, keep it in sync with code changes
- CLAUDE.md - personal Ivan's preferences of using Claude Code, suggest updates based on coding sessions in Claude
- TODO.md - informal list of changes to be done, bugs, new features etc, update it when implementing todo tasks from this file

## Branch & workflow
- **First action in any new session:** print `pwd` and `git branch --show-current` to confirm the workspace. If cwd is under `.claude/worktrees/*`, switch to the main repo dir (and remove the worktree if it's stale) before editing any file. The harness sometimes drops you in a worktree despite this preference.
- Always operate in the top-level repo directory (`/Users/Shared/git/github.com/pomodoro/`). Never `cd` into or edit files under `.claude/worktrees/*`.
- Prefer working directly on `main`. Use a feature branch only when explicitly asked.
- Ivan tests locally in Xcode on his iPhone before deciding to keep or revert.

## Pull requests
- Do not create PRs by default. Only create one when explicitly asked.
- When asked to merge a PR, default to `gh pr merge <num> --rebase --delete-branch`.
- When a PR completes a TODO.md entry, remove the entry in the same PR — don't leave it as a post-merge cleanup commit.

## Commits
- Don't auto-commit. Make the change, then wait for Ivan to review before committing.
- When Ivan asks to commit, stage only what's under review; don't batch unrelated changes.
- Don't `git push` unless explicitly asked.

## File and git access
- Read and edit any file in the project, even untracked or unstaged ones, without asking.
- Run any `git` or `gh` command without asking. Still confirm before destructive operations (`push --force`, `reset --hard`, `branch -D`, etc.).
- Run any standard CLI commands (`find`, `ls`, `mv`, `cp`, `grep`, `rm`, etc.) without asking.

## Planning & debugging
- For features touching iOS extensions, capabilities, or entitlements (App Groups, Keychain Sharing, Push Notifications, Background Modes, etc.), surface any paid Apple Developer Program dependency at planning time, before requesting manual Xcode steps. Ivan's account is currently free-tier pending approval.
- When uncertain whether a capability requires the paid Apple Developer Program, say so explicitly rather than asserting either way. Propose the cheapest possible verification first (e.g. wire only the entitlement and attempt a build) before writing dependent code.
- When diagnosing unclear behaviour (unexpected logs, intermittent failures, "this doesn't work"), label the diagnosis as a hypothesis and propose a way to verify it before applying the fix. Don't ship a fix justified by a guess.

## Code style
- SwiftUI + SwiftData, iOS 17+, MVVM architecture.
- App supports both portrait and landscape on iPhone. UI layouts must work in both — prefer proportional/responsive sizing (Grid column spans, `maxWidth: .infinity`, percentages) over fixed-point widths.
- No unnecessary comments. Only add a comment when the *why* is non-obvious.
- Don't add features, abstractions, or error handling beyond what the task requires.
- While the app is pre-production, refactors that improve testability or code quality are welcome — the no-extra-abstractions rule applies most strictly once we're shipping. When in doubt, ask.

## Communication
- Keep responses short and to the point.
- When referencing code, include file path and line number so Ivan can navigate directly.
- No emojis unless asked.

## Retrospectives
- When Ivan asks for a "Retrospective", after summarising lessons, always offer to update CLAUDE.md and `.claude/` settings to capture them. Wait for explicit approval before editing — these are repo-level files Ivan reviews before committing. Auto-memory under `~/.claude/...` can still be updated silently.
