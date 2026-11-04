import { expect, test } from 'claude-code/testing'

const SITE = {
  plugin: 'footer-status',
  component: 'SessionMode',
  props: { modes: ['focus'] },
} as const

const USAGE = {
  startedAt: 0,
  context: { tokens: 283_000, window: 1_000_000, percent: 28 },
  rateLimits: [],
  cost: { usd: 95.91 },
}

test('the footer keeps the mode labels and adds model, context, cost and directory', async ($, on) => {
  on('session.model', () => ({ value: 'claude-fable-5-1' }))
  on('session.usage', () => ({ value: USAGE }))
  on('session.cwd', () => ({ value: '/Users/someone/.config' }))
  // Stands for the engine's own drawing of the site.
  on('ui.render', { component: 'SessionMode' }, ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text dimColor>{e.props.modes.join(' & ')}</Text>
  })

  const ui = await $.ui.mount({ ...SITE, surface: 'terminal' })
  expect((await ui.find({ type: 'Text', text: /focus/ }))?.text).toBe('focus')
  expect((await ui.find({ type: 'Text', text: /Fable/ }))?.text).toBe('Fable 5.1')
  expect((await ui.find({ type: 'Text', text: /ctx/ }))?.text).toBe('ctx ███░░░░░░░ 28%')
  expect((await ui.find({ type: 'Text', text: /\$/ }))?.text).toBe('$95.91')
  expect((await ui.find({ type: 'Text', text: /config/ }))?.text).toBe('.config')
  await ui.unmount()
})

test('before the first reply the context shows no fill', async ($, on) => {
  on('session.model', () => ({ value: 'Fable 5.1' }))
  on('session.usage', () => ({ value: { ...USAGE, context: { window: 1_000_000 }, cost: undefined } }))
  on('session.cwd', () => ({ value: '/' }))
  on('ui.render', { component: 'SessionMode' }, ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text dimColor>{e.props.modes.join(' & ')}</Text>
  })

  const ui = await $.ui.mount({ ...SITE, props: { modes: [] }, surface: 'terminal' })
  expect((await ui.find({ type: 'Text', text: /ctx/ }))?.text).toBe('ctx ░░░░░░░░░░ --')
  expect(await ui.find({ type: 'Text', text: /\$/ })).toBeUndefined()
  await ui.unmount()
})
