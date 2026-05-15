<script lang="ts">
  // ANTI-PATTERN FIXTURE:
  // - $page from $app/stores (anti-pattern #22; should be `page` from $app/state)
  // - on:click event modifier (anti-pattern #4, #5)
  // - createEventDispatcher (anti-pattern #6)
  // - <slot> (anti-pattern #7)
  // - export let (anti-pattern #3)
  // - $: reactive statement (anti-pattern #2)
  // - new App boot pattern is in main.ts; here we focus on the SFC anti-patterns.

  import { page } from '$app/stores'
  import Counter from '$lib/Counter.svelte'
  import { createEventDispatcher } from 'svelte'

  export let title = 'Anti pattern home'
  let queryRaw = ''
  $: query = queryRaw.trim()

  const dispatch = createEventDispatcher<{ search: { q: string } }>()

  function submit(e: SubmitEvent) {
    dispatch('search', { q: query })
  }
</script>

<h1>{title}</h1>
<p>Path: {$page.url.pathname}</p>

<form on:submit|preventDefault={submit}>
  <input bind:value={queryRaw} type="search" />
  <button on:click={() => alert('hi')}>Go</button>
</form>

<Counter initial={3} on:change={(e) => console.log(e.detail.value)}>
  <slot />
  <slot name="footer" />
</Counter>
