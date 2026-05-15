// GOLD STANDARD:
// - Server `handle` hook for auth, populates locals.user from a session cookie.
// - cookies.set / cookies.delete always pass `path: '/'`.
// - Errors and redirects use the SvelteKit 2 form (no `throw`).
// - The universal `reroute` hook lives in src/hooks.ts, NOT here.

import type { Handle } from '@sveltejs/kit'

export const handle: Handle = async ({ event, resolve }) => {
  const sid = event.cookies.get('session')
  if (sid) {
    // Pretend lookup; in a real app this hits a session store.
    event.locals.user = { id: 'u_1', email: 'demo@example.com' }
  }
  return resolve(event)
}
