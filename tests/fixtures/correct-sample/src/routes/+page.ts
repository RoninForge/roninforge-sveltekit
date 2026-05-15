// GOLD STANDARD:
// - `satisfies PageLoad` propagates the literal return type into +page.svelte.
// - Pure synchronous return; no top-level unawaited promises.

import type { PageLoad } from './$types'

export const load = (async () => {
  return { now: new Date().toISOString() }
}) satisfies PageLoad
