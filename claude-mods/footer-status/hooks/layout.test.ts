import { expect, test } from 'claude-code/testing'

import { hintParts, layout, modeLabelColumns, timeLeft, usageText, width } from './layout'

const F = { model: 'Opus 5.5', percent: 32, usd: 107.48, dir: '.config' }
const COST = [{ text: '$107.48', percent: null }]
// A subscription: the session window at 39%, the weekly at 5%.
const PRO = { ...F, windows: [{ label: '5h', percent: 39 }, { label: 'wk', percent: 5 }] }

test('everything shows when there is room', () => {
  const l = layout(F, 200)
  expect(l).toEqual({ model: 'Opus 5.5', ctx: 'ctx ███░░░░░░░ 32%', usage: COST, dir: '.config' })
  expect(width(l)).toBe('Opus 5.5 | ctx ███░░░░░░░ 32% | $107.48 | .config'.length)
})

test('the model, then ctx, then the bar go first as the row narrows', () => {
  const full = width(layout(F, 200))
  expect(layout(F, full - 1).model).toBeUndefined()
  expect(layout(F, full - 1).ctx).toBe('ctx ███░░░░░░░ 32%')
  expect(layout(F, full - 12).ctx).toBe('███░░░░░░░ 32%')
  expect(layout(F, 24)).toEqual({ ctx: '32%', usage: COST, dir: '.config' })
})

test('then the directory, the cost, and last the percentage', () => {
  expect(layout(F, 15)).toEqual({ ctx: '32%', usage: COST })
  expect(layout(F, 5)).toEqual({ ctx: '32%' })
  expect(layout(F, 2)).toEqual({})
})

test('a subscription shows its windows in place of the cost', () => {
  const l = layout(PRO, 200)
  expect(usageText(l.usage ?? [])).toBe('5h 39% · wk 5%')
  expect(width(l)).toBe('Opus 5.5 | ctx ███░░░░░░░ 32% | 5h 39% · wk 5% | .config'.length)
  expect(l.usage).toEqual([
    { text: '5h 39%', percent: 39 },
    { text: 'wk 5%', percent: 5 },
  ])
})

test('on a subscription the window labels go after the bar and before the directory', () => {
  // "32% | 5h 39% · wk 5% | .config" is 30 columns; one fewer drops the labels.
  expect(usageText(layout(PRO, 30).usage ?? [])).toBe('5h 39% · wk 5%')
  expect(layout(PRO, 29)).toEqual({ ctx: '32%', usage: [{ text: '39%', percent: 39 }, { text: '5%', percent: 5 }], dir: '.config' })
  // then the directory, then the context percentage before the windows
  expect(usageText(layout(PRO, 23).usage ?? [])).toBe('39% · 5%')
  expect(layout(PRO, 23).dir).toBeUndefined()
  expect(layout(PRO, 13)).toEqual({ usage: [{ text: '39%', percent: 39 }, { text: '5%', percent: 5 }] })
  expect(layout(PRO, 8).usage).toBeDefined()
  // too narrow even for "39% · 5%": the context percentage is still drawn
  expect(layout(PRO, 7)).toEqual({ ctx: '32%' })
})

test('a subscription with no reading yet shows which windows it has', () => {
  expect(usageText(layout({ ...F, windows: [] }, 200).usage ?? [])).toBe('5h -- · wk --')
  expect(usageText(layout({ ...F, windows: [] }, 20).usage ?? [])).toBe('-- · --')
})

test('before the first reply the percentage reads --', () => {
  expect(layout({ ...F, percent: null }, 200).ctx).toBe('ctx ░░░░░░░░░░ --')
})

test('the hint loses "to manage" and keeps the rest', () => {
  expect(hintParts('2 shells · ↓ to manage')).toEqual({ kept: ['2 shells'], changed: true })
  expect(hintParts('esc to interrupt · 1 shell · ↓ to manage').kept).toEqual(['esc to interrupt', '1 shell'])
  expect(hintParts('? for shortcuts')).toEqual({ kept: ['? for shortcuts'], changed: false })
})

test('the mode label width is known per mode, widest when unknown', () => {
  expect(modeLabelColumns('default')).toBe(3)
  expect(modeLabelColumns('auto')).toBe(18)
  expect(modeLabelColumns(null)).toBe(modeLabelColumns('bypassPermissions'))
})

test('a window is labelled by the time left, rounded up', () => {
  const now = Date.parse('2026-11-05T12:00:00Z')
  const hours = (h: number) => now + h * 3_600_000
  expect(timeLeft({ label: '5h', percent: 39, resetsAt: hours(4.99) }, now)).toEqual({ label: '5h', percent: 39 })
  expect(timeLeft({ label: '5h', percent: 39, resetsAt: hours(2.5) }, now)).toEqual({ label: '3h', percent: 39 })
  expect(timeLeft({ label: '5h', percent: 39, resetsAt: hours(0.02) }, now)).toEqual({ label: '1h', percent: 39 })
  expect(timeLeft({ label: 'wk', percent: 5, resetsAt: hours(3.2 * 24) }, now)).toEqual({ label: '4d', percent: 5 })
  expect(timeLeft({ label: 'wk', percent: 5, resetsAt: hours(2) }, now)).toEqual({ label: '1d', percent: 5 })
})

test('past its reset a window shows its name and no figure; with no time, its name', () => {
  const now = Date.parse('2026-11-05T12:00:00Z')
  expect(timeLeft({ label: '5h', percent: 39, resetsAt: now - 1 }, now)).toEqual({ label: '5h', percent: null })
  expect(timeLeft({ label: 'wk', percent: 5, resetsAt: null }, now)).toEqual({ label: 'wk', percent: 5 })
  expect(timeLeft({ label: 'wk', percent: 5 }, now)).toEqual({ label: 'wk', percent: 5 })
})
