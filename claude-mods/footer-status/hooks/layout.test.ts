import { expect, test } from 'claude-code/testing'

import { hintParts, layout, modeLabelColumns, width } from './layout'

const F = { model: 'Opus 5.5', percent: 32, usd: 107.48, dir: '.config' }

test('everything shows when there is room', () => {
  const l = layout(F, 200)
  expect(l).toEqual({ model: 'Opus 5.5', ctx: 'ctx ███░░░░░░░ 32%', cost: '$107.48', dir: '.config' })
  expect(width(l)).toBe('Opus 5.5 | ctx ███░░░░░░░ 32% | $107.48 | .config'.length)
})

test('the model, then ctx, then the bar go first as the row narrows', () => {
  const full = width(layout(F, 200))
  expect(layout(F, full - 1).model).toBeUndefined()
  expect(layout(F, full - 1).ctx).toBe('ctx ███░░░░░░░ 32%')
  expect(layout(F, full - 12).ctx).toBe('███░░░░░░░ 32%')
  expect(layout(F, 24)).toEqual({ ctx: '32%', cost: '$107.48', dir: '.config' })
})

test('then the directory, the cost, and last the percentage', () => {
  expect(layout(F, 15)).toEqual({ ctx: '32%', cost: '$107.48' })
  expect(layout(F, 5)).toEqual({ ctx: '32%' })
  expect(layout(F, 2)).toEqual({})
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
