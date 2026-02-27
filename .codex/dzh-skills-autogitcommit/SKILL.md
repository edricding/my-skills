---
name: dzh-skills-autogitcommit
description: Generate GitHub-ready commit messages from repo changes with title/body length checks (title <=72, body line <=72). Trigger when users ask to summarize GitHub/project changes or write commit content, including "总结一下项目的github改动", "总结项目改动", and requests based on git status/diff.
---

# Auto Git Commit

## Overview

Summarize repository changes and draft commit text that is ready for `git commit`.
Produce:

- One commit title
- One commit body
- A short validation report for length and formatting

## Workflow

1. Inspect change scope.
- Prefer staged changes for commit drafting.
- Fall back to unstaged changes if nothing is staged.
- Always summarize only upload candidates (respect `.gitignore`).
- Run:
```bash
scripts/git_commit_digest.sh --mode auto --respect-gitignore on
```

2. Extract intent before writing.
- Identify "what changed" (files and behavior).
- Identify "why" (bug fix, feature, refactor, docs, maintenance).
- Collapse noisy implementation details into one concise user-facing summary.

3. Draft commit title.
- Prefer conventional format when suitable:
```text
<type>(<scope>): <summary>
```
- Use common types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `build`, `ci`.
- Keep title in imperative mood.
- Keep title length `<= 72` characters (prefer `<= 50` if still clear).
- Avoid ending title with a period.

4. Draft commit body.
- Start body after one blank line from the title.
- Focus on impact and reasoning, not line-by-line diff narration.
- Keep each body line `<= 72` characters.
- Prefer 3-8 bullet lines or short wrapped paragraphs.
- Mention testing/verification when relevant.

5. Validate message formatting.
- Run:
```bash
python3 scripts/validate_commit_message.py \
  --title "<TITLE>" \
  --body "<BODY>"
```
- If validation fails, shorten or re-wrap lines and validate again.

6. Return final output to user.
- Always return exactly this structure:
```text
Title:
<single-line title>

Body:
<multi-line body>
```

## Decision Rules

- If both staged and unstaged changes exist, summarize staged changes only unless user asks otherwise.
- Exclude files ignored by `.gitignore` from commit summaries.
- If no meaningful code changes exist, recommend no commit or suggest `chore`/`docs`.
- If change includes breaking behavior, add a clear breaking note in body.
- If repository has a known commit convention, follow it over generic rules.

## Resources

### `scripts/git_commit_digest.sh`

Generate digest of staged/unstaged diffs with:

- upload candidate list filtered by `.gitignore`
- name-status file list
- diff stat
- truncated patch preview

Use this output as the source context for commit drafting.

### `scripts/validate_commit_message.py`

Validate commit title/body structure and length:

- Title maximum length (default `72`)
- Body line maximum length (default `72`)
- Required blank line between title and body (when body exists)
- Common style checks (empty title, trailing period)
