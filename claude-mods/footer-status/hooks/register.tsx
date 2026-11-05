// footer-status: the prompt footer row as one line at any width.
//
//   ⏵⏵ auto mode on · 1 shell          Opus 5.5 | ctx ███░░░░░░░ 32% | $107.48 | .config
//
// The figures (the SessionMode site, right of the row) shrink to the room the
// row has left, so the row never wraps: see layout.ts for the order parts go
// in. The hint (PromptHint, left) loses "↓ to manage". The permission-mode
// label is the engine's own and no mod can change it; its width is counted.

import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { Snapshot } from '../types'
import { columns, hintParts, layout, modeLabelColumns, SEP } from './layout'
import { displayName } from './names'

const snapshot = atom({ plugin: 'footer-status', key: 'snapshot' } as const, null)
const mode = atom({ plugin: 'footer-status', key: 'mode' } as const, null)

// Columns kept free: the row's margins and the gap between its two halves.
const SLACK = 6

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
  // Columns the hint line takes as drawn; the figures fit around it.
  let hintColumns = 0

  on('session.start', async ($, e, next) => {
    await refresh($)
    return next(e)
  })

  // Fires after each turn and when a limit moves: the figures changed.
  on('session.measure', async ($, e, next) => {
    await refresh($)
    return next(e)
  })

  // The permission mode, for the width of the engine's label. These only
  // watch: on any failure the prompt or tool call goes on untouched.
  on('classic.UserPromptSubmit', async ($, e, next) => {
    if (e.permission_mode) await update($, mode, () => e.permission_mode ?? null)
    return next(e)
  }).catch(($, e, next) => next(e))
  on('classic.PostToolUse', async ($, e, next) => {
    if (e.permission_mode) await update($, mode, () => e.permission_mode ?? null)
    return next(e)
  }).catch(($, e, next) => next(e))

  on('ui.render', { component: 'PromptHint' }, async ($, e, next) => {
    const { kept, changed } = hintParts(e.props.hint)
    const drawn = columns(kept.join(' · '))
    if (drawn !== hintColumns) {
      hintColumns = drawn
      $.ui.invalidate('ui.render') // the figures re-fit to the new room
    }
    if (!changed) return next(e)

    const { Box, Text } = $.ui.resolve(e)
    return (
      <Box>
        {kept.map((part, i) => [
          i > 0 ? <Text dimColor> · </Text> : null,
          /^\d+ shells?$/.test(part) ? <Text color="cyan">{part}</Text> : <Text dimColor>{part}</Text>,
        ])}
      </Box>
    )
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

    const pct =
      s.percent ?? (s.tokens !== null && s.window > 0 ? Math.round((100 * s.tokens) / s.window) : null)
    const modes = e.props.modes.length > 0 ? columns(e.props.modes.join(' & ')) + 3 : 0
    const label = modeLabelColumns(await read($, mode))
    const left = label + (label > 0 && hintColumns > 0 ? 3 : 0) + hintColumns
    const room = e.viewport ? e.viewport.columns - left - modes - SLACK : Number.POSITIVE_INFINITY

    const l = layout({ model: displayName(s.model), percent: pct, usd: s.usd, dir: s.dir }, room)
    const hot = pct !== null && pct >= 80 ? 'red' : pct !== null && pct >= 60 ? 'yellow' : null

    const parts = []
    if (l.model) parts.push(<Text color="cyan">{l.model}</Text>)
    if (l.ctx) parts.push(hot ? <Text color={hot}>{l.ctx}</Text> : <Text dimColor>{l.ctx}</Text>)
    if (l.cost) parts.push(<Text dimColor>{l.cost}</Text>)
    if (l.dir) parts.push(<Text dimColor>{l.dir}</Text>)

    return (
      <Box>
        {engine}
        {e.props.modes.length > 0 && parts.length > 0 ? <Text dimColor> · </Text> : null}
        {parts.map((p, i) => [i > 0 ? <Text dimColor>{SEP}</Text> : null, p])}
      </Box>
    )
  })
}
