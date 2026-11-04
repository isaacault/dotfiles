// footer-status: draws "Fable 5.1 | ctx ███░░░░░░░ 28% | $95.91 | .config" on
// the prompt footer row, to the right of the mode labels ("auto mode on"),
// where a statusLine command would take a row of its own. Same figures and
// colours as ~/.claude/statusline.py, with the context fill drawn as a bar.
import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { Snapshot } from '../types'
import { displayName } from './names'

const snapshot = atom({ plugin: 'footer-status', key: 'snapshot' } as const, null)

const BAR_CELLS = 10

// Ten cells, filled in proportion to the context window used; all empty
// before the first reply, when there is no figure yet.
function bar(pct: number | null): string {
  if (pct === null) return '░'.repeat(BAR_CELLS)
  const filled = Math.min(BAR_CELLS, Math.max(0, Math.round((pct / 100) * BAR_CELLS)))
  return '█'.repeat(filled) + '░'.repeat(BAR_CELLS - filled)
}

function basename(path: string): string {
  const trimmed = path.replace(/\/+$/, '')
  return trimmed.slice(trimmed.lastIndexOf('/') + 1) || trimmed
}

async function measure($: EngineInterface): Promise<Snapshot> {
  const [model, usage, cwd] = await Promise.all([
    $.session.model(),
    $.session.usage(),
    $.session.cwd(),
  ])
  return {
    model,
    tokens: usage.context.tokens ?? null,
    window: usage.context.window,
    percent: usage.context.percent ?? null,
    usd: usage.cost?.usd ?? null,
    dir: basename(cwd),
  }
}

// Writing the snapshot redraws the footer: the render hook reads it.
async function refresh($: EngineInterface): Promise<void> {
  const next = await measure($)
  await update($, snapshot, () => next)
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await refresh($)
    return next(e)
  })

  // Fires after each turn and when a limit moves: the figures changed.
  on('session.measure', async ($, e, next) => {
    await refresh($)
    return next(e)
  })

  on('ui.render', { component: 'SessionMode' }, async ($, e, next) => {
    let s = await read($, snapshot)
    if (s === null) {
      try {
        s = await measure($)
      } catch {
        return next(e)
      }
    }

    const { Box, Text } = $.ui.resolve(e)
    const engine = await next(e)
    const sep = () => <Text dimColor> | </Text>

    const pct =
      s.percent ?? (s.tokens !== null && s.window > 0 ? Math.round((100 * s.tokens) / s.window) : null)
    const hot = pct !== null && pct >= 80 ? 'red' : pct !== null && pct >= 60 ? 'yellow' : null
    const ctx = pct === null ? `ctx ${bar(null)} --` : `ctx ${bar(pct)} ${pct}%`

    const parts = [
      <Text color="cyan">{displayName(s.model)}</Text>,
      sep(),
      hot ? <Text color={hot}>{ctx}</Text> : <Text dimColor>{ctx}</Text>,
    ]
    if (s.usd !== null) parts.push(sep(), <Text dimColor>${s.usd.toFixed(2)}</Text>)
    if (s.dir) parts.push(sep(), <Text dimColor>{s.dir}</Text>)

    return (
      <Box>
        {engine}
        {e.props.modes.length > 0 ? <Text dimColor> · </Text> : null}
        {parts}
      </Box>
    )
  })
}
