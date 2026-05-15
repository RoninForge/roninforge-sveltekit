---
name: svelte-new-component
description: "Scaffold a Svelte 5 single-file component using <script lang='ts'> with runes ($state, $derived, $props, $bindable), $props.id() for SSR-safe ARIA IDs, callback props for events (no createEventDispatcher), snippets for slots ({@render children?.()} for default, named snippet props for named), and a matching @testing-library/svelte test using render() (NOT mount or new App). Refuses on:click, $:, export let, <slot>, createEventDispatcher, withDefaults, CustomEvent typed handlers. Pairs with the svelte-5-runes, svelte-5-events-and-snippets, and sveltekit-anti-patterns rules."
---

# Scaffold a New Svelte 5 Component

## When to use

Use when:

- Creating a new component under `src/lib/components/`.
- A reviewer asked you to convert a Svelte 4 component to runes mode.
- An LLM emitted `export let` / `on:click` / `<slot>` / `createEventDispatcher` and you need the Svelte 5 form instead.

Target: `svelte ^5.55.7`. The companion `svelte-5-runes`, `svelte-5-events-and-snippets`, and `sveltekit-anti-patterns` rules cover the surrounding patterns.

## Output

For a component named `PostCard`, the scaffold writes one file:

```svelte
<!-- src/lib/components/PostCard.svelte -->
<script lang="ts">
  import type { Snippet } from 'svelte'
  import type { Post } from '$lib/types'

  type Props = {
    post: Post
    compact?: boolean
    onselect?: (postId: string) => void
    children?: Snippet
  }

  let { post, compact = false, onselect, children }: Props = $props()

  const uid = $props.id()
  let cardEl = $state<HTMLElement | undefined>()

  const onClick = () => onselect?.(post.id)
  const focus = () => cardEl?.focus()

  // Surface focus() to parents that hold a bind:this reference.
  // Svelte 5 components are not classes; the `focus` symbol is only reachable
  // if a parent imports it via a typed wrapper (or uses a snippet pattern).
</script>

<article
  bind:this={cardEl}
  class="post-card"
  class:post-card-compact={compact}
  tabindex="0"
  role="article"
  aria-labelledby="{uid}-title"
  aria-describedby="{uid}-summary"
  onclick={onClick}
  onkeydown={(e) => { if (e.key === 'Enter') onClick() }}
>
  <h2 id="{uid}-title">{post.title}</h2>
  {#if !compact && post.summary}
    <p id="{uid}-summary">{post.summary}</p>
  {/if}
  <time datetime={post.publishedAt}>{post.publishedAt}</time>
  {@render children?.()}
</article>

<style>
  .post-card {
    display: block;
    padding: 1rem;
    border: 1px solid #e2e8f0;
    border-radius: 0.5rem;
    cursor: pointer;
  }
  .post-card:focus-visible {
    outline: 2px solid #0369a1;
    outline-offset: 2px;
  }
  .post-card-compact { padding: 0.5rem; }
</style>
```

The matching test:

```ts
// src/lib/components/PostCard.test.ts
import { render, screen, fireEvent } from '@testing-library/svelte'
import { test, expect, vi } from 'vitest'
import PostCard from './PostCard.svelte'

const samplePost = {
  id: '1',
  title: 'Hello world',
  slug: 'hello-world',
  summary: 'A first post.',
  publishedAt: '2026-05-01T00:00:00Z',
}

test('renders the title', () => {
  render(PostCard, { props: { post: samplePost } })
  expect(screen.getByRole('article')).toHaveTextContent('Hello world')
})

test('hides the summary in compact mode', () => {
  render(PostCard, { props: { post: samplePost, compact: true } })
  expect(screen.queryByText('A first post.')).not.toBeInTheDocument()
})

test('calls onselect with the post id', async () => {
  const onselect = vi.fn()
  render(PostCard, { props: { post: samplePost, onselect } })
  await fireEvent.click(screen.getByRole('article'))
  expect(onselect).toHaveBeenCalledWith('1')
})
```

## Rules baked into the scaffold

1. **`<script lang="ts">`** with runes. No `<script>` without `lang="ts"`. (anti-pattern #1)
2. **No `$:` reactive statements.** Use `$derived`. (anti-pattern #2)
3. **No `export let`.** Use `let { ... } = $props()`. (anti-pattern #3)
4. **`onclick={fn}` not `on:click={fn}`.** No `on:` namespace. (anti-pattern #4)
5. **No event modifiers.** Handle in the function. (anti-pattern #5)
6. **Callback props for events**, not `createEventDispatcher`. (anti-pattern #6)
7. **`{@render children?.()}` not `<slot>`.** (anti-pattern #7)
8. **`$props.id()` for ARIA**, not hand-rolled IDs. (anti-pattern #36)
9. **`bind:this` to a `$state` variable** so consumers re-run. (anti-pattern #9)
10. **Defaults inline in `$props()` destructure**, no `withDefaults`. (anti-pattern #35)
11. **Snippet typing via `Snippet<[...]>`** from `svelte` for typed snippet args.
12. **Test uses `render()` from `@testing-library/svelte`**, not `mount(App)` and not `new App({ target })`. (anti-pattern #40)

## Workflow

1. **Name and place the file.** PascalCase, under `src/lib/components/<Domain>/<Name>.svelte`.
2. **Decide on props.** TypeScript inline. Defaults via destructure (`= 'md'`). Required props have no default.
3. **Decide on callbacks.** Optional callback props for events. Function signature is the payload.
4. **Place template refs.** Only the elements you need a JS handle on. Always `bind:this` to `$state`.
5. **Place IDs for ARIA.** `$props.id()` once per component instance; suffix per association point.
6. **Write the test.** Render, assert text, fire an event, assert the callback fired.
7. **Verify with `svelte-check`.** No errors expected.

## Examples

### Component with two-way binding via `$bindable`

```svelte
<!-- src/lib/components/TextInput.svelte -->
<script lang="ts">
  type Props = {
    value?: string
    label: string
    placeholder?: string
  }
  let { value = $bindable(''), label, placeholder = '' }: Props = $props()
  const uid = $props.id()
</script>

<label for="{uid}-i">{label}</label>
<input id="{uid}-i" type="text" bind:value {placeholder} />
```

Parent:

```svelte
<script lang="ts">
  import TextInput from '$lib/components/TextInput.svelte'
  let name = $state('')
</script>

<TextInput bind:value={name} label="Name" />
<p>Hello {name}</p>
```

### Generic list component

```svelte
<!-- src/lib/components/TypedList.svelte -->
<script lang="ts" generic="T extends { id: string }">
  import type { Snippet } from 'svelte'
  type Props = {
    items: T[]
    row: Snippet<[item: T, index: number]>
    empty?: Snippet
  }
  let { items, row, empty }: Props = $props()
</script>

<ul>
  {#each items as item, i (item.id)}
    <li>{@render row(item, i)}</li>
  {:else}
    {@render empty?.()}
  {/each}
</ul>
```

Parent:

```svelte
<TypedList items={posts}>
  {#snippet row(post)}
    <PostCard {post} />
  {/snippet}
  {#snippet empty()}
    <p>No posts.</p>
  {/snippet}
</TypedList>
```

### Component that fetches its own data via `$effect`

```svelte
<!-- src/lib/components/SearchBox.svelte -->
<script lang="ts">
  let query = $state('')
  let results = $state<string[]>([])

  $effect(() => {
    if (!query) { results = []; return }
    const ctrl = new AbortController()
    const q = query
    void (async () => {
      try {
        const r = await fetch(`/api/search?q=${encodeURIComponent(q)}`, { signal: ctrl.signal })
        if (!ctrl.signal.aborted) results = await r.json()
      } catch (e) {
        if ((e as Error).name !== 'AbortError') throw e
      }
    })()
    return () => ctrl.abort()
  })
</script>

<input bind:value={query} type="search" placeholder="Search." />
<ul>
  {#each results as r}
    <li>{r}</li>
  {/each}
</ul>
```

## Common mistakes the scaffold refuses

- **`export let post: Post`** in a runes file. Use `let { post } = $props()`. (anti-pattern #3)
- **`on:click={fn}`**. Use `onclick={fn}`. (anti-pattern #4)
- **`<slot />`** alongside `let { children } = $props()`. Use `{@render children?.()}`. (anti-pattern #7, #37)
- **`createEventDispatcher`**. Use callback props. (anti-pattern #6)
- **`withDefaults($props<Props>(), { ... })`**. Defaults inline in destructure. (anti-pattern #35)
- **`new App({ target })` in tests.** Use `render(Component)` from `@testing-library/svelte`. (anti-pattern #40)

## What this skill does NOT scaffold

- A page route. See `/sveltekit-new-route`.
- A form action. See `/sveltekit-new-form-action`.
- A shared state module. Write a `src/lib/state/<name>.svelte.ts` class with `$state` fields directly.
