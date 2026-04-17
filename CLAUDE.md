# Working preferences

## Important files
- SPEC.md - specification / Technical Requirements Document, keep it in sync with code changes
- CLAUDE.md - personal Ivan's preferences of using Claude Code, suggest updates based on coding sessions in Claude
- TODO.md - informal list of changes to be done, bugs, new features etc, update it when implementing todo tasks from this file

## Branch & workflow
- Always work directly on `main`. No worktrees, no feature branches, no PRs unless explicitly asked.
- Commit changes to `main` and push. Ivan tests locally in Xcode on his iPhone before deciding to keep or revert.

## Pull requests
- Do not create PRs by default. Only create one when explicitly asked.

## Commits
- Commit as soon as a logical change is complete. Don't batch unrelated changes into one commit.

## Code style
- SwiftUI + SwiftData, iOS 17+, MVVM architecture.
- No unnecessary comments. Only add a comment when the *why* is non-obvious.
- Don't add features, abstractions, or error handling beyond what the task requires.

## Communication
- Keep responses short and to the point.
- When referencing code, include file path and line number so Ivan can navigate directly.
- No emojis unless asked.
