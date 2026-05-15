---
name: sveltekit-migrate-to-runes
description: "Stage-by-stage migration from Svelte 4 + SvelteKit 1 to Svelte 5 (Runes) + SvelteKit 2: bump pins (svelte ^5.55.7, @sveltejs/kit ^2.60.1, vite ^8.0.13, typescript ^6.0.3, vitest ^4.1.6), enable runes mode, replace let with $state, $: with $derived, export let with $props, on:click with onclick, event modifiers with function-body handling, createEventDispatcher with callback props, <slot> with {@render children?.()}, new App({ target }) with mount(), drop throw on error/redirect, add path: '/' to cookies calls, await top-level promises in load (Promise.all), goto external -> window.location.href, $page from $app/stores -> page from $app/state, resolvePath -> resolveRoute, use:enhance form/data -> formElement/formData, add enctype on file forms, declare paths.relative: true, swap lucide-svelte for @lucide/svelte, swap melt-ui for bits-ui, swap Felte for sveltekit-superforms + formsnap + zod, swap <img> for <enhanced:img>, swap mount(App) tests for @testing-library/svelte render(), set vitest pool: 'forks'. Pairs with the sveltekit-anti-patterns rule (40 entries by number)."
---

# Migrate Svelte 4 + SvelteKit 1 to Svelte 5 (Runes) + SvelteKit 2

## When to use

Use when:

- An existing Svelte 4 + SvelteKit 1 codebase needs to upgrade.
- A reviewer flagged 10+ runes / SvelteKit 2 anti-patterns and a piecemeal fix is no longer viable.
- A vendor / contractor handed over code from before October 2024.

Target: `svelte ^5.55.7`, `@sveltejs/kit ^2.60.1`, `vite ^8.0.13`, `typescript ^6.0.3`, `vitest ^4.1.6`. The companion `sveltekit-anti-patterns` rule numbers each transformation.

## Migration stages

The Svelte team ships a codemod (`npx svelte-migrate svelte-5`) and a SvelteKit codemod (`npx svelte-migrate sveltekit-2`). Run them first; they handle the mechanical edits. The list below covers what they do plus what they miss.

### Stage 1: bump pins

```jsonc
// package.json
{
  "dependencies": {
    "svelte": "^5.55.7",
    "@sveltejs/kit": "^2.60.1"
  },
  "devDependencies": {
    "@sveltejs/vite-plugin-svelte": "^7.1.2",
    "vite": "^8.0.13",
    "typescript": "^6.0.3",
    "svelte-check": "^4.4.8",
    "vitest": "^4.1.6",
    "@testing-library/svelte": "^5.3.1",
    "@playwright/test": "^1.60.0",
    "tailwindcss": "^4.3.0"
  },
  "engines": { "node": ">=24" }
}
```

### Stage 2: turn runes on

```js
// svelte.config.js
const config = {
  compilerOptions: { runes: true },
  kit: {
    paths: { relative: true },  // SvelteKit 2 default; declared
  },
}
export default config
```

(For an opt-in-per-file approach, add `<svelte:options runes={true} />` at the top of a component.)

### Stage 3: Svelte 5 component shape

Per file, in this order:

1. **`export let prop` -> `let { prop } = $props()`** (anti-pattern #3)
2. **`let count = 0` (used as state) -> `let count = $state(0)`** (anti-pattern #1)
3. **`$: doubled = count * 2` -> `let doubled = $derived(count * 2)`** (anti-pattern #2)
4. **`$: { sideEffect() }` -> `$effect(() => { sideEffect() })`** (and check if it should actually be `$derived`) (anti-pattern #11)
5. **`on:click={fn}` -> `onclick={fn}`** (anti-pattern #4)
6. **`on:click|preventDefault={fn}` -> `onclick={(e) => { e.preventDefault(); fn(e) }}`** (anti-pattern #5)
7. **`createEventDispatcher` -> callback prop** (anti-pattern #6)
8. **`<slot />` -> `{@render children?.()}`**, `<slot name="x">` -> `{@render x?.()}` with `x` as a prop (anti-pattern #7)
9. **`bind:this={el}` with `let el` -> `let el = $state<HTMLElement | undefined>()`** (anti-pattern #9)
10. **`withDefaults`-style or per-prop defaults -> defaults inside `$props()` destructure** (anti-pattern #35)
11. **Hand-rolled ARIA IDs -> `$props.id()`** (anti-pattern #36)

### Stage 4: SvelteKit 2 changes

1. **`throw error(...)` -> `error(...)`**, **`throw redirect(...)` -> `redirect(...)`** (anti-pattern #17)
2. **`cookies.set('x', v, { httpOnly: true })` -> `cookies.set('x', v, { path: '/', httpOnly: true })`** (anti-pattern #19)
3. **`cookies.delete('x')` -> `cookies.delete('x', { path: '/' })`** (anti-pattern #19)
4. **Top-level unawaited promises in `load` -> `await Promise.all([...])`** (anti-pattern #20)
5. **`goto('https://external')` -> `window.location.href = '...'`** (anti-pattern #21)
6. **`import { page } from '$app/stores'` + `$page.url` -> `import { page } from '$app/state'` + `page.url`** (anti-pattern #22)
7. **`resolvePath` -> `resolveRoute`** (anti-pattern #23)
8. **`use:enhance={({ form, data }) => ...}` -> `use:enhance={({ formElement, formData }) => ...}`** (anti-pattern #24)
9. **File-input forms: add `enctype="multipart/form-data"`** (anti-pattern #25)
10. **Declare `kit.paths.relative: true` if hardcoded paths matter** (anti-pattern #26)
11. **Routes with `prerender = true` reading `$env/dynamic/*` -> use `$env/static/*`** (anti-pattern #27)

### Stage 5: typing

1. **`+page.ts` exports get `: PageLoad` or `satisfies PageLoad`** (anti-pattern #39)
2. **`actions` object gets `satisfies Actions`**
3. **Component event payloads typed `CustomEvent<T>` -> plain function arg types** (anti-pattern #34)

### Stage 6: state modules

1. **`writable()` / `readable()` for component-local -> `$state`** (anti-pattern #28)
2. **`writable` in `.ts` module for shared state -> class with `$state` in `.svelte.ts` module** (anti-pattern #29)
3. **Destructured `$state` proxy locals -> read through the proxy** (anti-pattern #10)

### Stage 7: dependencies

1. **`lucide-svelte` -> `@lucide/svelte`** (anti-pattern #30)
2. **`@melt-ui/svelte` -> `bits-ui` for new code** (anti-pattern #31)
3. **`felte` + `@felte/validator-zod` -> `sveltekit-superforms` + `formsnap` + `zod`** (anti-pattern #32)
4. **`<img>` for above-fold -> `<enhanced:img>` from `@sveltejs/enhanced-img`** (anti-pattern #33)

### Stage 8: tests

1. **`new App({ target })` and hand-rolled `mount(App, { target })` -> `render(Component)` from `@testing-library/svelte`** (anti-pattern #40)
2. **`vitest.config.ts`: declare `pool: 'forks'`** (Vitest 4 default flipped from v3)
3. **Cypress component tests removed; Playwright only for E2E** (anti-pattern from sveltekit-testing rule)

## Codemod commands

```bash
# Svelte 5 syntax migration (handles export let -> $props, $: -> $derived, on: -> onclick, slots -> snippets)
npx svelte-migrate svelte-5

# SvelteKit 2 migration (handles throw error / throw redirect, cookies path)
npx svelte-migrate sveltekit-2

# Run svelte-check to surface remaining type errors
pnpm svelte-check

# Run vitest to surface broken tests
pnpm vitest run
```

The codemod is conservative; it does NOT migrate stores to `$state`, replace `lucide-svelte` with `@lucide/svelte`, or restructure tests. Those are manual.

## Verification checklist

After running the codemods and applying the manual edits:

- [ ] `pnpm svelte-check` passes with 0 errors
- [ ] `pnpm vitest run` passes
- [ ] Grep for residual anti-patterns (these should all be empty):
  - `grep -rE "on:[a-z]+=" src/` (anti-pattern #4)
  - `grep -rE "^\s*\\\$:[^=]" src/` (anti-pattern #2 - `$:` reactive statements)
  - `grep -rE "^\s*export let " src/` (anti-pattern #3)
  - `grep -rE "<slot ?[/>]|<slot name=" src/` (anti-pattern #7)
  - `grep -rE "createEventDispatcher" src/` (anti-pattern #6)
  - `grep -rE "from '\$app/stores'" src/` (anti-pattern #22)
  - `grep -rE "throw redirect\(|throw error\(" src/` (anti-pattern #17)
  - `grep -rE "cookies\.(set|delete)\([^)]*\)" src/ | grep -v "path:"` (anti-pattern #19)
  - `grep -rE "from 'lucide-svelte'" src/` (anti-pattern #30)

## Common gotchas

- **Runes mode is per-file in 5.0 - 5.10, all-on by default in 5.20+.** If a partially-migrated file still uses `$:`, the compiler may interpret it as runes-mode and fail. Add `<svelte:options runes={true} />` explicitly until the whole component is migrated.
- **Mixing `<slot>` and `{@render children}` in the same component.** They do not co-exist. Pick one. (anti-pattern #37)
- **`bind:value` to a prop without `$bindable()`.** Throws in dev. Mark the prop bindable. (anti-pattern #38)
- **`$page.data` reads in templates after the import is rewritten to `$app/state`.** The `$` prefix is gone; reads become `page.data`.
- **`use:enhance` callback arg renames.** `form` is now `formElement`; `data` is now `formData`. Both are required to use the v2 enhance signature.

## What this skill does NOT do

- Migrate from a non-SvelteKit Svelte app (e.g. SvelteKit-less Vite + Svelte). The runes migration is the same; the SvelteKit 2 changes do not apply.
- Migrate from older Svelte (3.x). Run `npx svelte-migrate svelte-4` first, then this skill.
- Move you off Cypress component tests automatically; that is a hand rewrite.
