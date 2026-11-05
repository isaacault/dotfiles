// How the account is billed, as the footer last saw it: `subscription` (Pro,
// Max: five-hour and weekly windows) or `cost` (an enterprise budget, an API
// key, a gateway: dollars).
export type Billing = 'subscription' | 'cost'

// One subscription usage window: `5h` (the session window) or `wk`.
export type Limit = {
  label: string
  percent: number
  // When the window resets, in ms since the epoch; null or absent (a snapshot
  // an older version stored) when the response gave no time.
  resetsAt?: number | null
}

export type Snapshot = {
  model: string
  tokens: number | null
  window: number
  percent: number | null
  usd: number | null
  limits: Limit[]
  billing: Billing | null
  dir: string
}

declare module 'claude-code' {
  interface PluginState {
    'footer-status': {
      snapshot: Snapshot | null
      mode: string | null
      // A turn has been answered in this process, so the last API response's
      // rate-limit readings (or their absence) are this account's own.
      answered: boolean
    }
  }
}
