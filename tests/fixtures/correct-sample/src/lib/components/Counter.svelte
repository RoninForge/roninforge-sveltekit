<script lang="ts">
  // GOLD STANDARD:
  // - Runes: $state, $derived, $props with inline type and destructure default.
  // - Callback prop (onchange) is the v5 event mechanism.
  // - onclick attribute replaces on:click.

  type Props = {
    initial?: number
    onchange?: (value: number) => void
  }

  let { initial = 0, onchange }: Props = $props()

  let count = $state(initial)
  let doubled = $derived(count * 2)

  $effect(() => {
    onchange?.(count)
  })

  const inc = () => count++
  const dec = () => count--
</script>

<div class="counter">
  <button type="button" onclick={dec} aria-label="decrement">-</button>
  <span class="value">{count}</span>
  <button type="button" onclick={inc} aria-label="increment">+</button>
  <p class="doubled">Doubled: {doubled}</p>
</div>

<style>
  .counter { display: inline-flex; gap: 0.5rem; align-items: center; }
  .value { min-width: 2ch; text-align: center; font-variant-numeric: tabular-nums; }
  .doubled { margin-left: 1rem; color: #475569; }
</style>
