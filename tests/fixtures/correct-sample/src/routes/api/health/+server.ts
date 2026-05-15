// GOLD STANDARD:
// - +server.ts exports per HTTP method.
// - Typed `satisfies RequestHandler`.
// - json() helper from @sveltejs/kit.

import { json } from '@sveltejs/kit'
import type { RequestHandler } from './$types'

export const GET = (async () => {
  return json({ status: 'ok', time: new Date().toISOString() })
}) satisfies RequestHandler
