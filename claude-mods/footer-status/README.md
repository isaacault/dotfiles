# footer-status

A Claude Code mod that draws the model name, context-window fill as a ten-cell
bar with its percentage, session cost and current directory on the prompt
footer row, to the right of the mode labels such as "auto mode on", instead of
on a separate status-line row. Colours match `statusline.py` in the same
dotfiles: cyan model, the bar in yellow from 60% and red from 80%, everything
else dim. It runs inside Claude Code's hooks runtime: no model calls, no
subprocess, and the usage figures are the ones the status line already has,
so it costs no tokens and less CPU than a status-line command, which spawns a
process on every redraw. It refreshes after every
turn through the `session.measure` event.

The row never wraps. As the terminal narrows the figures drop, in order: the
model, the "ctx" label, the bar, the directory, the cost, and last the
percentage. The hint on the left loses "↓ to manage". The permission-mode label
("auto mode on") is drawn by Claude Code itself and no mod can hide it, so its
width is counted instead, from the default mode in settings
(`permissions.defaultMode`) plus a few columns of margin. A mod cannot watch
prompts or tool calls, so a shift+tab to a much longer label, such as bypass
permissions, can wrap the row until the next session.

Claude Code hands a mod the model ID (`claude-opus-5-5`), so the footer turns
it into the name the `/model` picker shows (`Opus 5.5`); a `[1m]` ID gets
`(1M context)`, and anything else is shown as it comes.

It is loaded from this folder, not linked into `~/.claude`: Claude Code reads
a plugin without following symlinks, so a stowed copy would not load. Try it
for one session with `claude --plugin-dir ~/dotfiles/claude-mods/footer-status`,
or for every session add to `~/.claude/settings.json`:

```json
"env": { "CLAUDE_CODE_PLUGIN_DIRS": "~/dotfiles/claude-mods/footer-status" }
```

Remove any `statusLine` entry from settings.json at the same time, or both rows
show. Terminal and Desktop only: the footer row does not exist in the IDE
extensions.
