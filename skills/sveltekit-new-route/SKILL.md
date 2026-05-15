---
name: sveltekit-new-route
description: "Scaffold a SvelteKit 2 route directory with +page.svelte (Svelte 5 runes consuming the data prop typed as PageData), +page.ts (universal load typed satisfies PageLoad with explicit awaits, no top-level unawaited promises), and +page.server.ts (server-only load + actions, error() / redirect() called without throw, cookies with explicit path: '/'). Refuses throw error / throw redirect / cookies without path / top-level unawaited promises in load. Pairs with the sveltekit-2-core, sveltekit-routing-and-load, and sveltekit-anti-patterns rules."
---

# Scaffold a New SvelteKit 2 Route

## When to use

Use when:

- Adding a new page under `src/routes/<segment>/`.
- Converting a SvelteKit 1 route to v2 (drop `throw`, add `path` to cookies, await top-level promises).
- A reviewer asked you to type a `+page.ts` `load` with `satisfies PageLoad`.

Target: `@sveltejs/kit ^2.60.1`. The companion `sveltekit-2-core`, `sveltekit-routing-and-load`, and `sveltekit-anti-patterns` rules cover the surrounding patterns.

## Output

For a route `/posts/[slug]`, the scaffold writes three files.

### `src/routes/posts/[slug]/+page.ts`

Universal load: runs on the server then on the client.

```ts
import { error } from '@sveltejs/kit'
import type { PageLoad } from './$types'
import type { Post } from '$lib/types'

export const load: PageLoad = async ({ params, fetch }) => {
  const res = await fetch(`/api/posts/${params.slug}`)
  if (!res.ok) error(res.status, 'Failed to load post')
  const post = (await res.json()) as Post
  return { post }
}
```

### `src/routes/posts/[slug]/+page.server.ts`

Server-only load + form action (use this if you need cookies, locals, or private env).

```ts
import { error, redirect, fail } from '@sveltejs/kit'
import type { PageServerLoad, Actions } from './$types'

export const load: PageServerLoad = async ({ params, locals }) => {
  const post = await locals.db.posts.findBySlug(params.slug)
  if (!post) error(404, 'Post not found')
  return { post }
}

export const actions = {
  delete: async ({ params, locals, cookies }) => {
    if (!locals.user) redirect(303, '/login')
    const ok = await locals.db.posts.deleteBySlug(params.slug)
    if (!ok) return fail(500, { message: 'Delete failed' })
    cookies.delete('lastPost', { path: '/' })
    redirect(303, '/posts')
  },
} satisfies Actions
```

### `src/routes/posts/[slug]/+page.svelte`

```svelte
<script lang="ts">
  import type { PageData } from './$types'
  let { data }: { data: PageData } = $props()
</script>

<svelte:head>
  <title>{data.post.title}</title>
</svelte:head>

<article>
  <h1>{data.post.title}</h1>
  <time datetime={data.post.publishedAt}>{data.post.publishedAt}</time>
  <p>{data.post.summary}</p>
</article>
```

### Optional: `src/routes/posts/[slug]/+server.ts` for a JSON API at the same path

```ts
import { json, error } from '@sveltejs/kit'
import type { RequestHandler } from './$types'

export const GET: RequestHandler = async ({ params, locals }) => {
  const post = await locals.db.posts.findBySlug(params.slug)
  if (!post) error(404, 'Not found')
  return json({ post })
}
```

## Rules baked into the scaffold

1. **`error()` and `redirect()` called without `throw`.** v2 made the helpers throw internally. (anti-pattern #17)
2. **`cookies.set` / `cookies.delete` always pass `{ path: '/', ... }`.** v2 made `path` mandatory. (anti-pattern #19)
3. **All top-level promises awaited explicitly** (or wrapped in `Promise.all`). v2 stopped auto-awaiting. (anti-pattern #20)
4. **`load` typed `satisfies PageLoad` / `PageServerLoad`.** Generated `$types` propagate to `+page.svelte`. (anti-pattern #39)
5. **`actions` object typed `satisfies Actions`** for the same reason.
6. **`fail(status, payload)` for validation failures**, not bare object returns.
7. **`+page.svelte` consumes `data` typed as `PageData`** with `let { data }: { data: PageData } = $props()`.
8. **No `throw` in front of `error` / `redirect`.** Period.
9. **No external URLs in `goto()`.** Use `window.location.href`. (anti-pattern #21)
10. **No `$page` from `$app/stores` in new code.** Use `page` from `$app/state`. (anti-pattern #22)

## Workflow

1. **Choose the segment.** Brackets for params (`[slug]`), double-brackets for optional (`[[lang]]`), `[...rest]` for catch-all.
2. **Decide load location.** `+page.ts` if it works without cookies / private env. `+page.server.ts` otherwise.
3. **Write `+page.ts` / `+page.server.ts` first.** Type with `satisfies PageLoad`. Use `Promise.all` for parallel fetches.
4. **Write `+page.svelte`.** Consume `data` typed as `PageData`.
5. **Add `+server.ts`** only if the route also serves JSON / non-page responses (e.g. RSS at `/posts.rss`).

## Examples

### Parallel fetches

```ts
import type { PageLoad } from './$types'

export const load: PageLoad = async ({ fetch, params }) => {
  const [post, comments] = await Promise.all([
    fetch(`/api/posts/${params.slug}`).then(r => r.json()),
    fetch(`/api/posts/${params.slug}/comments`).then(r => r.json()),
  ])
  return { post, comments }
}
```

### Streaming top-level (SvelteKit 2 explicit form)

```ts
import type { PageLoad } from './$types'

export const load: PageLoad = async ({ fetch, params }) => {
  const post = await fetch(`/api/posts/${params.slug}`).then(r => r.json())
  return {
    post,
    comments: fetch(`/api/posts/${params.slug}/comments`).then(r => r.json()),  // streamed
  }
}
```

```svelte
<script lang="ts">
  import type { PageData } from './$types'
  let { data }: { data: PageData } = $props()
</script>

<h1>{data.post.title}</h1>
{#await data.comments}
  <p>Loading comments.</p>
{:then comments}
  <ul>{#each comments as c}<li>{c.body}</li>{/each}</ul>
{/await}
```

### Manual invalidation

```ts
import type { PageLoad } from './$types'
import { invalidate } from '$app/navigation'

export const load: PageLoad = async ({ depends, fetch }) => {
  depends('app:posts')
  return { posts: await fetch('/api/posts').then(r => r.json()) }
}

// Later, after a mutation:
await invalidate('app:posts')
```

### Reading parent layout data

```ts
import type { PageLoad } from './$types'

export const load: PageLoad = async ({ parent }) => {
  const { user } = await parent()
  return { user }
}
```

## Common mistakes the scaffold refuses

- **`throw error(404, ...)`**. (anti-pattern #17)
- **`throw redirect(303, '/login')`**. (anti-pattern #17)
- **`cookies.set('session', tok, { httpOnly: true })` without `path`**. (anti-pattern #19)
- **Returning a top-level unawaited promise from `load`**. (anti-pattern #20)
- **`goto('https://stripe.example/checkout/abc')`**. (anti-pattern #21)
- **`+page.ts` without `PageLoad` type / `satisfies PageLoad`**. (anti-pattern #39)

## What this skill does NOT scaffold

- A form-heavy route. See `/sveltekit-new-form-action`.
- A reusable component. See `/svelte-new-component`.
- A `.svelte.ts` state module. Write the class directly under `src/lib/state/`.
