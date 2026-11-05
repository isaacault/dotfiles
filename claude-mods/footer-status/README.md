# footer-status

A Claude Code mod that draws the model name, context-window fill as a ten-cell
bar with its percentage, session cost (or, on a subscription, usage limits)
and current directory on the prompt footer row, to the right of the mode
labels such as "auto mode on", instead of on a separate status-line row: cyan
model, figures in yellow from 60% and red from 80%, everything else dim. It
runs inside Claude Code's hooks runtime: no model calls, no subprocess, and
the usage figures are the ones the status line would have, so it costs no
tokens and less CPU than a status-line command, which spawns a process on
every redraw. It refreshes after every turn through the `session.measure`
event.

The usage figure follows how the account is billed. An account that pays per
use (an enterprise budget, an API key, a gateway) shows the session cost,
`$107.48`. A Pro or Max subscription, where that figure is only an estimate,
shows the five-hour session window and the weekly window instead,
`5h 39% · wk 5%`, each coloured on its own. The account is told apart by the
rate-limit windows the API reports; the verdict is kept in the mod's store, so
a new session draws `5h -- · wk --` (or the cost) before its first reply, and
on a machine's very first session that slot stays empty until a turn is
answered.

The row never wraps. As the terminal narrows the figures drop, in order: the
model, the "ctx" label, the bar, on a subscription the window labels
(`5h 39% · wk 5%` becomes `39% · 5%`), the directory, and then the cost and
last the context percentage; on a subscription the context percentage goes
first and the two windows stay to the end. The hint on the left loses "↓ to manage". The permission-mode label
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
