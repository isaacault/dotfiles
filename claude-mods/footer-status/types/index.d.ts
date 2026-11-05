export type Snapshot = {
  model: string
  tokens: number | null
  window: number
  percent: number | null
  usd: number | null
  dir: string
}

declare module 'claude-code' {
  interface PluginState {
    'footer-status': { snapshot: Snapshot | null; mode: string | null }
  }
}
