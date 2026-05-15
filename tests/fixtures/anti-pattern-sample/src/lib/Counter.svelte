<script lang="ts">
  // ANTI-PATTERN FIXTURE: every line below violates a tracked rule.
  // - export let (anti-pattern #3)
  // - $: reactive statement (anti-pattern #2)
  // - createEventDispatcher (anti-pattern #6)
  // - on:click directive (anti-pattern #4)
  // - <slot /> (anti-pattern #7)
  // - lucide-svelte import (anti-pattern #30)

  import { createEventDispatcher } from 'svelte'
  import { Camera } from 'lucide-svelte'

  export let initial = 0
  export let label: string = 'Counter'

  let count = initial
  $: doubled = count * 2

  const dispatch = createEventDispatcher<{ change: { value: number } }>()

  function inc() {
    count++
    dispatch('change', { value: count })
  }
</script>

<div>
  <Camera />
  <h3>{label}</h3>
  <button on:click={inc}>{count}</button>
  <p>Doubled: {doubled}</p>
  <slot />
  <slot name="footer" />
</div>
