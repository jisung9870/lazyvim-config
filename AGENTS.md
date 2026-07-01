# AGENTS.md

## Repository Purpose

This is a personal LazyVim configuration for DevOps work across macOS and WSL.
Keep changes portable, small, and easy to recover on a new machine.

## Working Rules

- Prefer existing LazyVim extras and local plugin patterns before adding a new dependency.
- Keep machine-specific settings out of git. Use `lua/config/local.lua` for local Neovim settings.
- Never commit secrets, tokens, private hostnames, or machine-local paths unless they are already documented as examples.
- Use `rg`/`rg --files` for searches.
- Use `apply_patch` for manual file edits.
- Do not rewrite unrelated plugin pins or user changes.

## File Ownership

- `README.md`: human-facing setup overview and navigation.
- `AGENTS.md`: durable agent and contributor rules for this repo.
- `CLAUDE.md`: Claude Code entrypoint; it should import `AGENTS.md` and avoid duplicating rules.
- `doc/*.txt`: Neovim help documents users can open with `:help`.
- `lua/config/keymaps.lua`: custom non-plugin keymaps.
- `lua/plugins/*.lua`: plugin specs and plugin-specific keymaps.
- `lazy-lock.json`: pinned plugin versions only.

## Help Documentation

- Add reusable Neovim documentation under `doc/*.txt`.
- Every help file must have at least one unique help tag like `*lazyvim-cheatsheet*`.
- Prefer repo-specific tag prefixes such as `lazyvim-*` or `nvim-*`; avoid generic tags like `*keys*`.
- After adding or changing help docs, run:

```bash
nvim --headless "+helptags doc" "+h lazyvim-cheatsheet" +qa
```

- Track `doc/tags` in git so `:help lazyvim-cheatsheet` works immediately after checkout.
- User-facing key or workflow docs belong in help files, not only in README comments.

## Keymap Rules

- Add a `desc` for every keymap so which-key can display it.
- Avoid taking common LazyVim groups unless the behavior clearly belongs there.
- For Git keys, keep this split:
  - `<leader>gg`: Git UI
  - `<leader>gG`: commit graph
  - `<leader>gq`: close Diffview
- If a keymap changes, update `doc/lazyvim-cheatsheet.txt` in the same change.

## Plugin And Lockfile Rules

- When adding a plugin, update the relevant `lua/plugins/*.lua` file and let Lazy create a lock entry.
- If `Lazy! sync` updates unrelated plugins, revert those unrelated lockfile changes before finishing.
- `lazy-lock.json` should include only intentional plugin additions or updates.
- Do not run broad plugin upgrades unless the user explicitly asks for them.

## Commit Rules

Use Conventional Commits:

- `feat(git): add gitgraph commit view`
- `docs(help): add LazyVim cheatsheet`
- `docs(agent): add agent workflow guide`
- `chore(lock): pin gitgraph.nvim`
- `fix(yaml): correct schema selection mapping`

Commit separation:

- Separate config behavior, docs/help, and broad lockfile updates when practical.
- Do not mix unrelated plugin version bumps into feature commits.
- Include generated `doc/tags` with help documentation changes.

Commit message body:

- Do not leave only a one-line subject for non-trivial changes.
- Add a body that explains what changed, why it changed, and how it was verified.
- Mention user-visible behavior, keymaps, help tags, or migration notes when relevant.
- Example:

```text
docs(agent): add shared maintenance rules

Document the shared AGENTS.md workflow so Codex and Claude Code follow the
same help, lockfile, and commit conventions.

Verification:
- nvim --headless "+helptags doc" "+h nvim-maintenance" +qa
- git diff --check
```

## Verification

Use the smallest relevant checks:

```bash
git diff --check
nvim --headless "+helptags doc" "+h lazyvim-cheatsheet" +qa
stylua --check lua/**/*.lua
./scripts/test-setup.sh
```

- Run `stylua --check` when Lua files changed.
- Run the help check when `doc/*.txt` changed.
- Run `./scripts/test-setup.sh` when setup scripts, install flow, or platform behavior changed.
- If a check is unavailable locally, report that clearly.

## Agent Behavior

- Read the relevant local files before proposing or making changes.
- Preserve unrelated dirty worktree changes.
- Prefer narrow, reversible edits.
- When changing user-facing workflow, update both implementation and help documentation.
