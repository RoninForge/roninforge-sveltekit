// GOLD STANDARD:
// - sveltekit-superforms + zod for typed form validation.
// - error() / redirect() called WITHOUT throw.
// - cookies.set with explicit path: '/'.
// - fail() for validation failures (status code reflects outcome).
// - actions typed `satisfies Actions`.

import { fail, redirect } from '@sveltejs/kit'
import { superValidate, message } from 'sveltekit-superforms'
import { zod } from 'sveltekit-superforms/adapters'
import { z } from 'zod'
import type { PageServerLoad, Actions } from './$types'

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8, 'Password must be at least 8 characters'),
})

export const load: PageServerLoad = async ({ locals }) => {
  if (locals.user) redirect(303, '/')
  return { form: await superValidate(zod(loginSchema)) }
}

export const actions = {
  default: async ({ request, cookies }) => {
    const form = await superValidate(request, zod(loginSchema))
    if (!form.valid) return fail(400, { form })

    if (form.data.email !== 'demo@example.com') {
      return message(form, 'Invalid credentials', { status: 401 })
    }

    cookies.set('session', 'sess_123', {
      path: '/',
      httpOnly: true,
      secure: true,
      sameSite: 'lax',
      maxAge: 60 * 60 * 24 * 7,
    })
    redirect(303, '/')
  },
} satisfies Actions
