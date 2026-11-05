// Fits the footer figures to the room the row has, dropping parts in this
// order as it narrows: the model, the "ctx" label, the bar, on a subscription
// the "5h"/"wk" labels, the directory, then the usage figure and last the
// context percentage, except on a subscription, where the context percentage
// goes before the windows ("39% · 5%" outlasts it).

// One subscription window as drawn: `5h` (the session window) or `wk`, and
// how full it is (null before the first reading).
export type Window = {
  label: string
  percent: number | null
}

export type Figures = {
  model: string
  percent: number | null
  usd: number | null
  // Set on a subscription: its windows, drawn in place of the cost.
  windows?: Window[] | null
  dir: string
}

// A piece of the usage figure, coloured by how full it is (null: never hot).
export type Piece = {
  text: string
  percent: number | null
}

export type Layout = {
  model?: string
  ctx?: string
  usage?: Piece[]
  dir?: string
}

export const BAR_CELLS = 10
export const SEP = ' | '
// Between the pieces of the usage figure: "5h 39% · wk 5%".
export const PIECE_SEP = ' · '

// A subscription with no reading yet still shows which windows it has.
const PLACEHOLDER: Window[] = [
  { label: '5h', percent: null },
  { label: 'wk', percent: null },
]

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

export function usageText(pieces: Piece[]): string {
  return pieces.map(p => p.text).join(PIECE_SEP)
}

export function width(l: Layout): number {
  const usage = l.usage === undefined ? undefined : usageText(l.usage)
  const parts = [l.model, l.ctx, usage, l.dir].filter((p): p is string => p !== undefined)
  return parts.reduce((n, p) => n + columns(p), 0) + SEP.length * Math.max(0, parts.length - 1)
}

function percentText(pct: number | null): string {
  return pct === null ? '--' : `${Math.round(pct)}%`
}

// The usage figure, widest form first: on a subscription "5h 39% · wk 5%",
// then "39% · 5%"; otherwise the cost, "$107.48", which has one form.
function usageForms(f: Figures): [wide?: Piece[], narrow?: Piece[]] {
  if (f.windows != null) {
    const ws = f.windows.length > 0 ? f.windows : PLACEHOLDER
    return [
      ws.map(w => ({ text: `${w.label} ${percentText(w.percent)}`, percent: w.percent })),
      ws.map(w => ({ text: percentText(w.percent), percent: w.percent })),
    ]
  }
  const cost = f.usd === null ? undefined : [{ text: `$${f.usd.toFixed(2)}`, percent: null }]
  return [cost, cost]
}

export function layout(f: Figures, room: number): Layout {
  const pct = percentText(f.percent)
  const [usage, short] = usageForms(f)
  const dir = f.dir || undefined
  const candidates: Layout[] = [
    { model: f.model, ctx: `ctx ${bar(f.percent)} ${pct}`, usage, dir },
    { ctx: `ctx ${bar(f.percent)} ${pct}`, usage, dir },
    { ctx: `${bar(f.percent)} ${pct}`, usage, dir },
    { ctx: pct, usage, dir },
    { ctx: pct, usage: short, dir },
    { ctx: pct, usage: short },
    // a subscription keeps its windows over the context; with no room for
    // them either, the context percentage is still drawn
    ...(f.windows != null ? [{ usage: short }] : []),
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
