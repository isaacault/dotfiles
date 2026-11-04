// Model IDs as the /model picker names them: claude-opus-5-5 is "Opus 5.5",
// claude-sonnet-5 is "Sonnet 5", claude-haiku-4-5-20251001 is "Haiku 4.5", and
// a [1m] suffix adds "(1M context)". $.session.model() answers with the ID, so
// the footer converts it here. Anything not shaped like an ID is shown as is.

const ID = /^claude-([a-z]+)-(\d+)(?:-(\d{1,2}))?(?:-\d{8})?(\[1m\])?$/i

export function displayName(model: string): string {
  const m = ID.exec(model.trim())
  if (!m) return model
  const [, family = '', major = '', minor, longContext] = m
  const name = family.charAt(0).toUpperCase() + family.slice(1).toLowerCase()
  const version = minor === undefined ? major : `${major}.${minor}`
  return `${name} ${version}${longContext ? ' (1M context)' : ''}`
}
