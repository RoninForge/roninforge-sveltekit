<script lang="ts">
  // GOLD STANDARD:
  // - $props() with Snippet typing for children.
  // - {@render children?.()} is the v5 way to render the default snippet prop.
  // - page imported from $app/state (NOT $app/stores).

  import type { Snippet } from 'svelte'
  import { page } from '$app/state'

  type Props = { children?: Snippet }
  let { children }: Props = $props()
</script>

<header>
  <nav>
    <a href="/">Home</a>
    <a href="/login">Login</a>
  </nav>
  <small>Path: {page.url.pathname}</small>
</header>

<main>
  {@render children?.()}
</main>

<footer>
  <small>Correct sample &middot; SvelteKit 2 + Svelte 5</small>
</footer>

<style>
  header, footer { padding: 1rem; border-bottom: 1px solid #e2e8f0; }
  footer { border-top: 1px solid #e2e8f0; border-bottom: none; }
  nav { display: flex; gap: 1rem; }
  main { padding: 1rem; }
</style>
