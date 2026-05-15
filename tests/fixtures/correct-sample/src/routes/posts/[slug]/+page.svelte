<script lang="ts">
  // GOLD STANDARD:
  // - data prop typed as PageData.
  // - No $page from $app/stores; no slots; no event directives; no exports.

  import type { PageData } from './$types'

  let { data }: { data: PageData } = $props()
</script>

<svelte:head>
  <title>{data.post.title}</title>
</svelte:head>

<article>
  <h1>{data.post.title}</h1>
  <time datetime={data.post.publishedAt}>{data.post.publishedAt}</time>
  {#if data.post.summary}
    <p>{data.post.summary}</p>
  {/if}
</article>
