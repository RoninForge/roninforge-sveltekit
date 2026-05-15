<script lang="ts">
  // GOLD STANDARD:
  // - $props.id() (Svelte 5.20+) for SSR-safe ARIA IDs.
  // - $bindable() for two-way value binding.
  // - bind:this targets a $state variable.

  type Props = {
    value?: string
    label: string
    placeholder?: string
    onsubmit?: (value: string) => void
  }

  let {
    value = $bindable(''),
    label,
    placeholder = '',
    onsubmit,
  }: Props = $props()

  const uid = $props.id()
  let inputEl = $state<HTMLInputElement | undefined>()

  const submit = () => {
    if (value.trim()) onsubmit?.(value.trim())
  }

  const onKey = (e: KeyboardEvent) => {
    if (e.key === 'Enter') {
      e.preventDefault()
      submit()
    }
  }
</script>

<div class="field">
  <label for="{uid}-input">{label}</label>
  <input
    id="{uid}-input"
    bind:this={inputEl}
    bind:value
    type="search"
    {placeholder}
    onkeydown={onKey}
    aria-describedby="{uid}-hint"
  />
  <p id="{uid}-hint" class="hint">Press Enter to search.</p>
</div>

<style>
  .field { display: flex; flex-direction: column; gap: 0.25rem; }
  .hint { color: #64748b; font-size: 0.875rem; }
</style>
