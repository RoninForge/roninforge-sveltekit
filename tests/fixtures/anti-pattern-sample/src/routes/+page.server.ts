// ANTI-PATTERN FIXTURE:
// - throw redirect / throw error (anti-pattern #17)
// - cookies.set / cookies.delete without `path: '/'` (anti-pattern #19)
// - top-level unawaited promise in load (anti-pattern #20)

import { error, redirect } from '@sveltejs/kit'
import type { PageServerLoad, Actions } from './$types'

export const load: PageServerLoad = async ({ locals, fetch }) => {
  if (!locals.user) {
    throw redirect(303, '/login')
  }

  // Top-level unawaited promise; SvelteKit 2 will surface it as Promise<unknown>.
  return {
    posts: fetch('/api/posts').then((r) => r.json()),
  }
}

export const actions: Actions = {
  delete: async ({ cookies, locals }) => {
    if (!locals.user) {
      throw error(401, 'Unauthorized')
    }
    cookies.set('lastDelete', String(Date.now()), { httpOnly: true })
    cookies.delete('session')
  },
}
