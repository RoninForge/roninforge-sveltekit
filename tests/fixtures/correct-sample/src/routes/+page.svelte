<script lang="ts">
  // GOLD STANDARD:
  // - data prop typed as PageData.
  // - Counter component used with callback prop.
  // - cart shared state from .svelte.ts module.

  import type { PageData } from './$types'
  import Counter from '$lib/components/Counter.svelte'
  import SearchInput from '$lib/components/SearchInput.svelte'
  import { cart } from '$lib/state/cart.svelte'

  let { data }: { data: PageData } = $props()

  let lastQuery = $state('')

  function addSample() {
    cart.add({ id: crypto.randomUUID(), name: 'Sample item', price: 9.99 })
  }
</script>

<h1>Welcome</h1>
<p>Server time at load: {data.now}</p>

<section>
  <h2>Counter</h2>
  <Counter initial={5} onchange={(n) => console.log('count is', n)} />
</section>

<section>
  <h2>Search</h2>
  <SearchInput label="Query" onsubmit={(q) => (lastQuery = q)} />
  {#if lastQuery}
    <p>You searched for: <strong>{lastQuery}</strong></p>
  {/if}
</section>

<section>
  <h2>Cart ({cart.count})</h2>
  <button type="button" onclick={addSample}>Add sample item</button>
  <ul>
    {#each cart.items as item (item.id)}
      <li>{item.name} &times; {item.quantity} - ${item.price.toFixed(2)}</li>
    {/each}
  </ul>
  <p>Total: ${cart.total.toFixed(2)}</p>
</section>
