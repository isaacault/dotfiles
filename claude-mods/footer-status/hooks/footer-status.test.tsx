import { expect, test } from 'claude-code/testing'
import type { On } from 'claude-code'

const SITE = {
  plugin: 'footer-status',
  component: 'SessionMode',
  props: { modes: ['focus'] },
} as const

const USAGE = {
  startedAt: 0,
  context: { tokens: 283_000, window: 1_000_000, percent: 28 },
  rateLimits: [] as { kind: string; percentUsed: number; resetsAt?: string }[],
  cost: { usd: 95.91 },
}

const SUBSCRIPTION = [
  { kind: 'five_hour', percentUsed: 23.5 },
  { kind: 'seven_day', percentUsed: 81 },
]

// Stands for the engine: the session's figures, its own drawing of the site,
// and a store holding `stored` under the billing key (writes land in `writes`).
function engine(on: On, usage: typeof USAGE, stored?: string, writes: unknown[] = []) {
  on('session.model', () => ({ value: 'claude-fable-5-1' }))
  on('session.usage', () => ({ value: usage }))
  on('session.cwd', () => ({ value: '/Users/someone/.config' }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('store.get', () => ({ value: stored }))
  on('store.set', (_, e) => {
    writes.push(e.value)
    return { value: undefined }
  })
  on('ui.render', { component: 'SessionMode' }, ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text dimColor>{e.props.modes.join(' & ')}</Text>
  })
}

const ANSWER = { reason: 'answer', answer: 'done', durationMs: 1, isAborted: false, turnId: 't1' } as const

test('an account billed in dollars keeps model, context, cost and directory', async ($, on) => {
  engine(on, USAGE, 'cost')

  const ui = await $.ui.mount({ ...SITE, surface: 'terminal' })
  expect((await ui.find({ type: 'Text', text: /focus/ }))?.text).toBe('focus')
  expect((await ui.find({ type: 'Text', text: /Fable/ }))?.text).toBe('Fable 5.1')
  expect((await ui.find({ type: 'Text', text: /ctx/ }))?.text).toBe('ctx ███░░░░░░░ 28%')
  expect((await ui.find({ type: 'Text', text: /\$/ }))?.text).toBe('$95.91')
  expect(await ui.find({ type: 'Text', text: /5h/ })).toBeUndefined()
  expect((await ui.find({ type: 'Text', text: /config/ }))?.text).toBe('.config')
  await ui.unmount()
})

test('a subscription shows the session and weekly windows in place of the cost', async ($, on) => {
  const writes: unknown[] = []
  engine(on, { ...USAGE, rateLimits: SUBSCRIPTION }, undefined, writes)
  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })

  const ui = await $.ui.mount({ ...SITE, surface: 'terminal' })
  expect((await ui.find({ type: 'Text', text: /5h/ }))?.text).toBe('5h 24%')
  expect((await ui.find({ type: 'Text', text: /wk/ }))?.text).toBe('wk 81%')
  expect(await ui.find({ type: 'Text', text: /\$/ })).toBeUndefined()
  expect(writes).toEqual(['subscription'])
  await ui.unmount()
})

test('a known subscription with no reading yet draws placeholders, not a stale cost', async ($, on) => {
  engine(on, USAGE, 'subscription')

  const ui = await $.ui.mount({ ...SITE, surface: 'terminal' })
  expect((await ui.find({ type: 'Text', text: /5h/ }))?.text).toBe('5h --')
  expect((await ui.find({ type: 'Text', text: /wk/ }))?.text).toBe('wk --')
  expect(await ui.find({ type: 'Text', text: /\$/ })).toBeUndefined()
  await ui.unmount()
})

test('on a first run nothing is drawn for billing until a turn is answered', async ($, on) => {
  const writes: unknown[] = []
  engine(on, USAGE, undefined, writes)
  on('turn.complete', () => ({ text: 'done' }))
  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })

  const ui = await $.ui.mount({ ...SITE, surface: 'terminal' })
  expect(await ui.find({ type: 'Text', text: /\$/ })).toBeUndefined()
  expect(await ui.find({ type: 'Text', text: /5h/ })).toBeUndefined()

  // An answer with no subscription window in it: this account pays per use.
  await $.turn.complete(ANSWER)
  expect((await ui.find({ type: 'Text', text: /\$/ }))?.text).toBe('$95.91')
  expect(writes).toEqual(['cost'])
  await ui.unmount()
})

test('before the first reply the context shows no fill', async ($, on) => {
  engine(on, { ...USAGE, context: { window: 1_000_000 } as typeof USAGE.context, cost: undefined as never }, 'cost')

  const ui = await $.ui.mount({ ...SITE, props: { modes: [] }, surface: 'terminal' })
  expect((await ui.find({ type: 'Text', text: /ctx/ }))?.text).toBe('ctx ░░░░░░░░░░ --')
  expect(await ui.find({ type: 'Text', text: /\$/ })).toBeUndefined()
  await ui.unmount()
})

test('on a narrow terminal a subscription keeps both windows as bare percentages', async ($, on) => {
  engine(on, { ...USAGE, rateLimits: [{ kind: 'five_hour', percentUsed: 39 }, { kind: 'seven_day', percentUsed: 5 }] }, 'subscription')

  // 56 columns: the widest mode label (24) and the slack (6) leave 26, room for
  // "28% | 39% · 5% | .config" (24) but not "28% | 5h 39% · wk 5% | .config" (30).
  const ui = await $.ui.mount({ ...SITE, props: { modes: [] }, surface: 'terminal', viewport: { columns: 56, rows: 24 } })
  expect(await ui.find({ type: 'Text', text: /5h|wk|ctx|Fable/ })).toBeUndefined()
  expect((await ui.find({ type: 'Text', text: /^39%$/ }))?.text).toBe('39%')
  expect((await ui.find({ type: 'Text', text: /^5%$/ }))?.text).toBe('5%')
  expect((await ui.find({ type: 'Text', text: /config/ }))?.text).toBe('.config')
  await ui.unmount()
})

test('the hint line drops "to manage" and keeps the shell count', async ($, on) => {
  on('ui.render', ($, e) => {
    const { Text } = $.ui.resolve(e)
    return <Text>engine</Text>
  })
  const ui = await $.ui.mount({
    plugin: 'footer-status',
    component: 'PromptHint',
    props: { isDraft: false, isWorking: false, hint: '2 shells · ↓ to manage' },
    surface: 'terminal',
  })
  expect((await ui.find({ type: 'Text', text: /shells/ }))?.text).toBe('2 shells')
  expect(await ui.find({ type: 'Text', text: /manage/ })).toBeUndefined()
  await ui.unmount()
})
