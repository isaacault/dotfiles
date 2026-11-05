// footer-status: the prompt footer row as one line at any width.
//
//   ⏵⏵ auto mode on · 1 shell          Opus 5.5 | ctx ███░░░░░░░ 32% | $107.48 | .config
//   ⏵⏵ auto mode on · 1 shell   Opus 5.5 | ctx ███░░░░░░░ 32% | 5h 39% · wk 5% | .config
//
// The figures (the SessionMode site, right of the row) shrink to the room the
// row has left, so the row never wraps: see layout.ts for the order parts go
// in. The hint (PromptHint, left) loses "↓ to manage". The permission-mode
// label is the engine's own and no mod can change it; its width is counted.
//
// The usage figure follows how the account is billed: dollars where it pays
// per use (an enterprise budget, an API key), and the session and weekly
// windows on a subscription (Pro, Max), where the dollar figure is only an
// estimate.

import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register, SessionRateLimit } from 'claude-code'

import type { Billing, Limit, Snapshot } from '../types'
import { columns, hintParts, layout, modeLabelColumns, PIECE_SEP, SEP } from './layout'
import { displayName } from './names'

const snapshot = atom({ plugin: 'footer-status', key: 'snapshot' } as const, null)
const mode = atom({ plugin: 'footer-status', key: 'mode' } as const, null)
const answered = atom({ plugin: 'footer-status', key: 'answered' } as const, false)

// Remembered across sessions, so a new or resumed session draws the right
// usage figure before its first reply has reported any rate limits.
const BILLING_KEY = 'billing'

// The subscription windows, in the order drawn; a gateway's `spend_limit` is
// not one of them (that account is billed in dollars).
const WINDOWS: [kind: string, label: string][] = [
  ['five_hour', '5h'],
  ['seven_day', 'wk'],
]

// Columns kept free: the row's margins and the gap between its two halves.
const SLACK = 6

function basename(path: string): string {
  const trimmed = path.replace(/\/+$/, '')
  return trimmed.slice(trimmed.lastIndexOf('/') + 1) || trimmed
}

function limitsOf(rateLimits: readonly SessionRateLimit[]): Limit[] {
  const out: Limit[] = []
  for (const [kind, label] of WINDOWS) {
    const w = rateLimits.find(l => l.kind === kind)
    if (w) out.push({ label, percent: w.percentUsed })
  }
  return out
}

function isBilling(v: unknown): v is Billing {
  return v === 'subscription' || v === 'cost'
}

// Subscription windows in the last response settle it. With none, an answered
// turn means the account has none (pays per use); before any answer, the last
// session's verdict stands, and on a first run nothing is drawn yet.
function billingOf(limits: Limit[], hasAnswered: boolean, stored: unknown): Billing | null {
  return limits.length > 0 ? 'subscription' : hasAnswered ? 'cost' : isBilling(stored) ? stored : null
}

async function measure($: EngineInterface): Promise<Snapshot> {
  const [model, usage, cwd, hasAnswered, stored] = await Promise.all([
    $.session.model(),
    $.session.usage(),
    $.session.cwd(),
    read($, answered),
    $.store.get(BILLING_KEY),
  ])
  const limits = limitsOf(usage.rateLimits)
  return {
    model,
    tokens: usage.context.tokens ?? null,
    window: usage.context.window,
    percent: usage.context.percent ?? null,
    usd: usage.cost?.usd ?? null,
    limits,
    billing: billingOf(limits, hasAnswered, stored),
    dir: basename(cwd),
  }
}

// Writing the snapshot redraws the footer: the render hook reads it. The
// billing verdict is kept for the next session here, never while drawing.
async function refresh($: EngineInterface): Promise<void> {
  const next = await measure($)
  await update($, snapshot, () => next)
  if (next.billing !== null && next.billing !== (await $.store.get(BILLING_KEY))) {
    await $.store.set(BILLING_KEY, next.billing)
  }
}

// Yellow from 60%, red from 80%.
function heat(pct: number | null): 'red' | 'yellow' | null {
  return pct !== null && pct >= 80 ? 'red' : pct !== null && pct >= 60 ? 'yellow' : null
}

export const register: Register = on => {
  // Columns the hint line takes as drawn; the figures fit around it.
  let hintColumns = 0

  on('session.start', async ($, e, next) => {
    await refresh($)
    // The width of the engine's mode label is reckoned from the configured
    // default mode: a mod cannot watch prompts or tool calls (the built-in
    // guard runs first and passes them on), so it never sees a shift+tab.
    try {
      const configured = await $.settings.read({ key: 'permissions' })
      const dm = (configured as { defaultMode?: unknown } | undefined)?.defaultMode
      if (typeof dm === 'string') await update($, mode, () => dm)
    } catch {
      // unknown: the widest label is reserved
    }
    return next(e)
  })

  // Fires after each turn and when a limit moves: the figures changed.
  on('session.measure', async ($, e, next) => {
    await refresh($)
    return next(e)
  })

  // An answer means an API response reached this process, so its rate-limit
  // readings, or their absence, now describe this account.
  on('turn.complete', async ($, e, next) => {
    if (e.reason === 'answer' && !(await read($, answered))) {
      await update($, answered, () => true)
      await refresh($)
    }
    return next(e)
  })

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

    // A snapshot an older version stored has no billing: it draws the cost.
    // A first run (billing still null) draws neither until a turn is answered.
    const windows = s.billing === 'subscription' ? (s.limits ?? []) : null
    const usd = s.billing === 'subscription' || s.billing === null ? null : s.usd
    const l = layout({ model: displayName(s.model), percent: pct, usd, windows, dir: s.dir }, room)

    const figure = (text: string, percent: number | null) => {
      const hot = heat(percent)
      return hot ? <Text color={hot}>{text}</Text> : <Text dimColor>{text}</Text>
    }

    const parts = []
    if (l.model) parts.push(<Text color="cyan">{l.model}</Text>)
    if (l.ctx) parts.push(figure(l.ctx, pct))
    if (l.usage) {
      parts.push(l.usage.map((p, i) => [i > 0 ? <Text dimColor>{PIECE_SEP}</Text> : null, figure(p.text, p.percent)]))
    }
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
