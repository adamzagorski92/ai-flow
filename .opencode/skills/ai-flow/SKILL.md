---
name: ai-flow
description: >
  Use when working on features in the ai-flow repository.
  Follows the Research -> Plan -> Execute loop with feature branches.
  Load when user mentions "feature agent", "ai-flow", "research plan execute",
  "feature branch", "TODO.md", "READY.md", or when opening a PR to develop.
---

# AI Flow Workflow

This repository uses the **AI Flow** methodology:

- **`master`** = stable release
- **`develop`** = integration branch
- **`feature/<name>/<task>`** = one change, one PR

## Key files
- `AGENTS.md` — AI workflow rules
- `Flow-solution.md` — Git flow setup
- `Agent-flow.md` — Agent role definitions and diagrams
- `READY.md` — Canonical registry of merged capabilities
- `TODO.md` — Active iterations and suggestions

## Research -> Plan -> Execute

1. **Research**: Check `READY.md`, `TODO.md`, existing code, tests.
2. **Plan**: Pick smallest next step. Update `TODO.md`.
3. **Execute**: One branch, one PR. Commit, test, push.

## Branch rules
- Always branch from latest `develop`.
- Never edit directly on `develop` or `master`.
- Rebase before every push: `git fetch origin && git rebase origin/develop`.
- Push with `--force-with-lease` only on your own `feature/...` branch.

## PR rules
- One PR = one topic.
- Approval from different GitHub identity than author.
- `Rebase and merge` only.
- After push, ask user if task is complete. If yes, switch to `develop` and clean up.

## Agent roles
- **Feature Agent**: Creates code, opens PR to `develop`.
- **Develop Integration Agent**: Rebases, resolves conflicts, merges to `develop`.
- **Release Agent**: Manages `develop -> master` PR.
