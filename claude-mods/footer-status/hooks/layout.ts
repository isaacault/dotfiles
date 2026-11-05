// Fits the footer figures to the room the row has, dropping parts in this
// order as it narrows: the model, the "ctx" label, the bar, the directory, the
// cost, and last the percentage.

export type Figures = {
  model: string
  percent: number | null
  usd: number | null
  dir: string
}

export type Layout = {
  model?: string
  ctx?: string
  cost?: string
  dir?: string
}

export const BAR_CELLS = 10
export const SEP = ' | '

export function columns(text: string): number {
  return [...text].length
}

// Ten cells, filled in proportion to the context window used; all empty
// before the first reply, when there is no figure yet.
export function bar(pct: number | null): string {
  if (pct === null) return '░'.repeat(BAR_CELLS)
  const filled = Math.min(BAR_CELLS, Math.max(0, Math.round((pct / 100) * BAR_CELLS)))
  return '█'.repeat(filled) + '░'.repeat(BAR_CELLS - filled)
}

export function width(l: Layout): number {
  const parts = [l.model, l.ctx, l.cost, l.dir].filter((p): p is string => p !== undefined)
  return parts.reduce((n, p) => n + columns(p), 0) + SEP.length * Math.max(0, parts.length - 1)
}

export function layout(f: Figures, room: number): Layout {
  const pct = f.percent === null ? '--' : `${f.percent}%`
  const cost = f.usd === null ? undefined : `$${f.usd.toFixed(2)}`
  const dir = f.dir || undefined
  const candidates: Layout[] = [
    { model: f.model, ctx: `ctx ${bar(f.percent)} ${pct}`, cost, dir },
    { ctx: `ctx ${bar(f.percent)} ${pct}`, cost, dir },
    { ctx: `${bar(f.percent)} ${pct}`, cost, dir },
    { ctx: pct, cost, dir },
    { ctx: pct, cost },
    { ctx: pct },
  ]
  return candidates.find(c => width(c) <= room) ?? {}
}

// Width of the permission-mode label the engine draws at the start of the
// row ("⏵⏵ auto mode on"). Mods cannot redraw or hide it, so the row's room
// is reckoned around it, from the configured default mode plus MODE_MARGIN
// for a shift+tab to a slightly longer label; an unknown mode reserves the
// widest.
const MODE_LABEL: Record<string, number> = {
  default: 0,
  auto: columns('⏵⏵ auto mode on'),
  acceptEdits: columns('⏵⏵ accept edits on'),
  plan: columns('⏸ plan mode on'),
  bypassPermissions: columns('⏵⏵ bypass permissions on'),
}
const WIDEST_LABEL = Math.max(...Object.values(MODE_LABEL))

const MODE_MARGIN = 3

export function modeLabelColumns(mode: string | null): number {
  if (mode === null || MODE_LABEL[mode] === undefined) return WIDEST_LABEL
  return Math.min(WIDEST_LABEL, MODE_LABEL[mode] + MODE_MARGIN)
}

// The hint line minus the parts not wanted ("↓ to manage").
export function hintParts(hint: string): { kept: string[]; changed: boolean } {
  const parts = hint.split(' · ')
  const kept = parts.filter(p => !/\bto manage$/i.test(p.trim()))
  return { kept, changed: kept.length !== parts.length }
}
