// GOLD STANDARD:
// - error() and redirect() called WITHOUT throw (SvelteKit 2).
// - Action object typed `satisfies Actions`.
// - cookies.set / cookies.delete with explicit path: '/'.
// - fail() for validation failures.

import { error, redirect, fail } from '@sveltejs/kit'
import type { PageServerLoad, Actions } from './$types'

type Post = {
  id: string
  slug: string
  title: string
  summary?: string
  publishedAt: string
}

const fakeDb: Record<string, Post> = {
  hello: {
    id: '1',
    slug: 'hello',
    title: 'Hello world',
    summary: 'A first post.',
    publishedAt: '2026-05-01T00:00:00Z',
  },
}

export const load: PageServerLoad = async ({ params }) => {
  const post = fakeDb[params.slug]
  if (!post) error(404, 'Post not found')
  return { post }
}

export const actions = {
  delete: async ({ params, locals, cookies }) => {
    if (!locals.user) redirect(303, '/login')

    const post = fakeDb[params.slug]
    if (!post) return fail(404, { message: 'Post not found' })

    delete fakeDb[params.slug]
    cookies.delete('lastPost', { path: '/' })
    redirect(303, '/')
  },
} satisfies Actions
