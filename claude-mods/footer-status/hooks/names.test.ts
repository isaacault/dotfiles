import { expect, test } from 'claude-code/testing'

import { displayName } from './names'

test('model IDs become the names the /model picker shows', () => {
  expect(displayName('claude-opus-5-5')).toBe('Opus 5.5')
  expect(displayName('claude-opus-5')).toBe('Opus 5')
  expect(displayName('claude-sonnet-5')).toBe('Sonnet 5')
  expect(displayName('claude-fable-5-1')).toBe('Fable 5.1')
  expect(displayName('claude-haiku-4-5-20251001')).toBe('Haiku 4.5')
  expect(displayName('claude-sonnet-5-20260101')).toBe('Sonnet 5')
  expect(displayName('claude-opus-5-5[1m]')).toBe('Opus 5.5 (1M context)')
})

test('anything that is not a model ID is shown unchanged', () => {
  expect(displayName('Opus 5.5')).toBe('Opus 5.5')
  expect(displayName('claude-3-5-sonnet-20241022')).toBe('claude-3-5-sonnet-20241022')
  expect(displayName('my-gateway-model')).toBe('my-gateway-model')
})
