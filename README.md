# roninforge-sveltekit

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Cursor plugin for SvelteKit 2 + Svelte 5 (Runes) + TypeScript. Pinned to `svelte ^5.55.7` and `@sveltejs/kit ^2.60.1`. Teaches the Svelte 5 runes that LLMs trained pre-October 2024 do not know (`$state`, `$derived`, `$props`, `$bindable`, `$effect`, `$props.id()`), the snippets-replace-slots model, callback props that replace `createEventDispatcher`, the `.svelte.ts` state module pattern that replaces `writable()` stores, the SvelteKit 2 no-throw `error()` / `redirect()` API, mandatory cookies `path`, and the `$app/state` replacement for `$app/stores` in 2.12+. Catches 40 LLM regressions with BAD / GOOD TypeScript + Svelte pairs.

## The Problem

LLMs trained on Svelte 4 / SvelteKit 1 emit code that does not match a fresh Svelte 5 + SvelteKit 2 install. They write:

- **`let count = 0`** for component state without `$state(0)` (silently non-reactive in runes mode)
- **`$: doubled = count * 2`** in runes-mode files (syntax error)
- **`export let prop`** in any file using runes (compile error)
- **`<button on:click={fn}>`** with the `on:` namespace (removed in Svelte 5)
- **Event modifiers** `|preventDefault`, `|stopPropagation`, `|self`, `|once` (removed)
- **`createEventDispatcher`** + `dispatch('foo', payload)` (replaced by callback props)
- **`<slot />`** and `<slot name="x" />` (replaced by snippets and `{@render children?.()}`)
- **`new App({ target })`** for the client root or for tests (Svelte 5 dropped the class instance API; use `mount()` or `render()`)
- **`bind:this={el}`** to a non-`$state` variable (assignment is invisible to consumers)
- **Destructuring a `$state` proxy** and reading the destructured local (loses reactivity)
- **`$effect`** used to derive a value (use `$derived`)
- **`$effect`** that reads and writes the same state (infinite loop; wrap in `untrack`)
- **`$state`** for arrays larger than 1000 elements without considering `$state.raw`
- **`$effect`** used to initialise state on the server (effects only run in the browser)
- **Reading state inside `$effect` after `await`** (no longer tracked)
- **`throw error(...)` / `throw redirect(...)`** in SvelteKit 2 (helpers throw internally; just call them)
- **Wrapping `redirect()` in try/catch** without `isRedirect` re-throw (silently swallowed)
- **`cookies.set` / `cookies.delete`** without explicit `path: '/'` (throws in SvelteKit 2)
- **Top-level unawaited promises in `load`** (SvelteKit 2 stopped auto-awaiting; use `Promise.all`)
- **`goto('https://external')`** (rejected in SvelteKit 2; use `window.location.href`)
- **`$page` from `$app/stores`** in new code (use `page` from `$app/state`, 2.12+)
- **`resolvePath`** (renamed `resolveRoute` in `$app/paths`)
- **`use:enhance` callback args `form` / `data`** (renamed `formElement` / `formData` in v2)
- **File-input forms** missing `enctype="multipart/form-data"` (throws under enhance)
- **`$env/dynamic/*`** read inside a prerendered route (use `$env/static/*`)
- **`writable()` / `readable()` stores** for component-local state (use `$state`)
- **Stores in plain `.ts` modules** for shared cross-component state (use `.svelte.ts` with a class)
- **`lucide-svelte` import** (use `@lucide/svelte`, the scoped Svelte 5 fork)
- **`@melt-ui/svelte`** in new Svelte 5 code (use `bits-ui`, the documented headless layer)
- **Felte forms** (`felte` + `@felte/validator-zod`) effectively abandoned for SvelteKit (use `sveltekit-superforms` + `formsnap` + `zod`)
- **`<img>`** for above-the-fold images (use `<enhanced:img>` from `@sveltejs/enhanced-img`)
- **`CustomEvent<T>`** typed payloads in handlers (callback props pass plain function args)
- **`withDefaults`-style prop defaults** (Svelte 5 supports defaults inline in `$props()` destructure)
- **Manually generating SSR-safe IDs for ARIA** (use `$props.id()` in 5.20+)
- **`<slot>`** rendered alongside `let { children } = $props()` (the two systems do not co-exist)
- **Mutating non-`$bindable` props** in the child (throws in dev)
- **`+page.ts`** exports without `satisfies PageLoad` (loses generated-type propagation)
- **`mount(App)`** in tests without `unmount()` (handlers leak across tests; use `@testing-library/svelte`)

## Why this plugin (vs the existing community Svelte / SvelteKit rules)

A handful of Svelte and SvelteKit rules already live on cursor.directory: `svelte.mdc`, `sveltekit.mdc`, `svelte-tailwind.mdc`, and a few mixed-stack files. They are shallow and have three structural problems this plugin fixes:

1. **They pin nothing or pin pre-Svelte-5 / pre-Kit-2.** Across all of them, zero mentions of `$state`, `$derived`, `$props`, `$bindable`, `$effect`, `$props.id()`, snippets, callback-prop event handling, `.svelte.ts` state modules, `mount()` / `hydrate()`, the SvelteKit 2 no-throw `error()` / `redirect()`, mandatory `cookies.path`, top-level `Promise.all` in `load`, `$app/state`, or the `formElement` / `formData` rename in `use:enhance`. Svelte 5 (October 2024) and SvelteKit 2 (December 2023, with $app/state in 2.12) post-date all of them. This plugin pins `svelte ^5.55.7` and `@sveltejs/kit ^2.60.1` explicitly.
2. **Most still teach `on:click` / `<slot>` / `createEventDispatcher` / `export let` / `writable()` for component state.** All five are deprecated or compile errors in Svelte 5 runes mode. They also teach `$page` from `$app/stores` (deprecated 2.12+) and `throw redirect(...)` (broken in v2).
3. **They ship flat `.cursorrules` text without globs, fixtures, skills, or an agent.** This plugin ships:

   - **10 MDC rules** with proper `globs` so the routes check fires on `src/routes/**`, the runes check on `**/*.svelte` + `**/*.svelte.ts`, the testing check on `**/*.test.ts`, etc.
   - **40 documented anti-patterns** with BAD / GOOD TypeScript + Svelte pairs (the existing rules have zero)
   - **5 skills**: `/svelte-new-component`, `/sveltekit-new-route`, `/sveltekit-new-form-action`, `/sveltekit-migrate-to-runes`, `/sveltekit-validate`
   - **1 reviewer agent** with severity grouping (CRITICAL / ERROR / WARN / NIT) and per-file checks
   - **2 fixture projects**: `correct-sample` (gold-standard SvelteKit 2.60.1 + Svelte 5.55.7 + bits-ui + sveltekit-superforms + formsnap + zod) and `anti-pattern-sample` (every file violates at least one tracked anti-pattern, pinned to `svelte ^4.2.0` + `@sveltejs/kit ^1.27.0` + `lucide-svelte ^0.300.0` to demonstrate the Svelte 4 / Kit 1 hangover)

## Install

Copy the rules, skills, and agent into your project's Cursor configuration. Back up your existing files first; `cp -r` will overwrite same-named rules.

```bash
git clone https://github.com/RoninForge/roninforge-sveltekit.git

# Use -n to avoid clobbering an existing customised rule of the same name.
cp -rn roninforge-sveltekit/rules/*  your-project/.cursor/rules/
cp -rn roninforge-sveltekit/skills/* your-project/.cursor/skills/
cp -rn roninforge-sveltekit/agents/* your-project/.cursor/agents/
```

Or vendor the whole repo as a git submodule under `your-project/.cursor/plugins/`. Refer to the [Cursor plugin docs](https://docs.cursor.com/plugins) for the current global-install path on your Cursor version.

## What's Included

### Rules (10 files)

| Rule | Scope (globs) | What it does |
|------|---------------|--------------|
| `sveltekit-anti-patterns` | `**/*.svelte,**/*.svelte.ts,**/*.svelte.js,**/*.ts,**/*.js,src/routes/**/*,src/hooks.{server,client}.{ts,js}` | 40 LLM regressions with BAD / GOOD pairs. Each entry annotates which Svelte / Kit version dropped or renamed the BAD form |
| `svelte-5-runes` | `**/*.svelte,**/*.svelte.ts,**/*.svelte.js` | `$state`, `$state.raw`, `$state.snapshot`, `$derived`, `$derived.by`, `$effect`, `$effect.pre`, `$effect.tracking`, `$effect.root`, `$props`, `$props.id`, `$bindable`, `$host`, `$inspect` |
| `svelte-5-events-and-snippets` | `**/*.svelte` | `onclick` / `oninput` / `onsubmit` plain DOM attributes, callback props for component events, `Snippet<[T]>` typing, `{#snippet}` declarations, `{@render}` rendering |
| `sveltekit-2-core` | `src/routes/**/*.{ts,js,svelte},src/hooks.ts,src/hooks.js,src/hooks.{server,client}.{ts,js},svelte.config.{js,ts}` | `error()` / `redirect()` no longer thrown, `cookies` `path` mandatory, top-level `load` promises require explicit await, `goto()` rejects external URLs, `$app/state` replaces `$app/stores` (2.12+), `resolvePath` -> `resolveRoute`, `paths.relative` default flip, `reroute` hook, shallow routing |
| `sveltekit-routing-and-load` | `src/routes/**/*.{ts,js,svelte}` | `+page.svelte` / `+page.ts` / `+page.server.ts` / `+layout.*` / `+error.svelte` / `+server.ts`, `satisfies PageLoad`, `depends()`, `parent()`, `fetch()` proxy, route param patterns, route groups |
| `sveltekit-forms-and-actions` | `src/routes/**/+page.server.{ts,js},src/routes/**/+page.svelte,src/routes/**/+layout.server.{ts,js}` | Form actions, `use:enhance` v2 callback args, multipart enctype on file forms, `sveltekit-superforms` + `formsnap` + `zod` canonical stack |
| `sveltekit-app-state` | `src/routes/**/*.{ts,js,svelte},src/lib/**/*.{ts,js,svelte}` | `page` / `navigating` / `updated` reactive objects from `$app/state` (2.12+), migration cheat sheet from `$app/stores` |
| `svelte-5-reactivity-traps` | `**/*.svelte,**/*.svelte.ts,**/*.svelte.js` | Eight common runes traps: `$effect` SSR-only, reads after await not tracked, infinite loop on read+write, `$effect` for derivation, large arrays + `$state.raw`, destructuring a proxy, mutating non-`$bindable`, `bind:this` to non-`$state` |
| `svelte-5-typescript` | `**/*.svelte,**/*.svelte.ts,**/*.svelte.js,**/*.ts` | `$props<T>()` inline typing, `Snippet<[...]>` generic, `Component<...>` generic, `satisfies PageLoad` / `Actions`, generic components via `<script lang="ts" generic="T">`, discriminated unions for variant props, `$bindable` typing |
| `sveltekit-testing` | `**/*.test.{ts,js},**/*.spec.{ts,js},vitest.config.{ts,js},playwright.config.{ts,js},e2e/**/*` | Vitest 4 (`pool: 'forks'` default flip), `@testing-library/svelte` 5 `render()`, `happy-dom`, mocking `$app/state` / `$app/navigation`, `.svelte.ts` test setup, Playwright 1.60 for E2E (Cypress NOT recommended) |

### Skills (5 commands)

| Skill | Command | What it does |
|-------|---------|--------------|
| New component | `/svelte-new-component` | Scaffold a `.svelte` component using runes (`$state`, `$derived`, `$props`, `$bindable`), `$props.id()` for ARIA, callback props for events, snippets for slots, plus a matching `@testing-library/svelte` test using `render()` |
| New route | `/sveltekit-new-route` | Scaffold a route directory with `+page.svelte`, `+page.ts` (typed `satisfies PageLoad`), `+page.server.ts` (typed `satisfies Actions`), and optional `+server.ts`. `error()` / `redirect()` without `throw`, `cookies` with `path` |
| New form action | `/sveltekit-new-form-action` | Scaffold a `sveltekit-superforms` + `formsnap` + `zod` form: one schema, `superValidate(zod(schema))` on server load + action, `superForm(data.form, { validators: zodClient(schema) })` on client. `fail()` for validation, `message()` for action-level errors |
| Migrate to Runes | `/sveltekit-migrate-to-runes` | Stage-by-stage migration: bump pins, enable runes, run `svelte-migrate svelte-5` and `svelte-migrate sveltekit-2` codemods, then manual edits for each numbered anti-pattern (state modules, dependencies, tests) |
| Validate | `/sveltekit-validate` | Run `validate-plugin.sh` + `svelte-check` + `vitest` + `playwright`, then a grep audit for syntactic anti-patterns the type checker won't catch |

### Agent (1 subagent)

| Agent | What it does |
|-------|--------------|
| `sveltekit-reviewer` | Reviews SvelteKit 2 + Svelte 5 + TypeScript code by severity. CRITICAL: `throw error` / `throw redirect`, `cookies` without `path`, `redirect()` swallowed in try/catch, `$effect` initialising SSR-visible state, `$effect` infinite loop. ERROR: bare `let` for state, `$:` reactive statements, `export let`, `on:click` and event modifiers, `createEventDispatcher`, `<slot>` in runes file, `new App({ target })`, top-level unawaited `load` promises, `goto` external, `$app/stores`, `enhance` callback args `form/data`, file form without enctype, `$env/dynamic` during prerender, `bind:this` to non-`$state`. WARN: `$effect` for derivation, large `$state` array, reads after await in `$effect`, destructured `$state`, `writable()` for local state, `lucide-svelte`, `@melt-ui/svelte`, Felte, raw `<img>`, `CustomEvent<T>`, `withDefaults`, manual ARIA IDs, `<slot>` alongside `{@render children}`, mutating non-`$bindable`, `+page.ts` without `satisfies PageLoad`, `mount(App)` in tests, `paths.relative` not declared, `vitest` `pool` not declared. NIT: `$inspect` left in shipped code, missing `satisfies Actions`, missing `depends()` key, missing `fail()`, per-form `enhance` import |

## Fixtures

`tests/fixtures/correct-sample/` is a slim SvelteKit 2.60.1 + Svelte 5.55.7 + bits-ui + sveltekit-superforms + formsnap + zod project demonstrating the gold-standard shape: runes everywhere, callback props, snippets, `.svelte.ts` state module, `page` from `$app/state`, `error()` / `redirect()` without `throw`, `cookies` with `path`, `satisfies PageLoad` / `Actions`, superforms-wired login, `reroute` hook.

`tests/fixtures/anti-pattern-sample/` is the inverse. Every file violates a numbered anti-pattern. `package.json` pins `svelte ^4.2.0` + `@sveltejs/kit ^1.27.0` + `lucide-svelte ^0.300.0` + `vitest ^0.34.0` on purpose - the Svelte 4 / Kit 1 era is the LLM-training dataset for most pre-2025 models. Tracked violations: `#2` (`$:`), `#3` (`export let`), `#4` (`on:click`), `#5` (event modifiers), `#6` (`createEventDispatcher`), `#7` (`<slot>`), `#17` (`throw redirect / throw error`), `#19` (`cookies` without `path`), `#20` (top-level unawaited load), `#22` (`$page` from `$app/stores`), `#28` (`writable` for component-local), `#29` (`.ts` shared store), `#30` (`lucide-svelte`).

## Versioning

Rules target `svelte ^5.55.7` on `@sveltejs/kit ^2.60.1` with Node 24 LTS. Most patterns work back to Svelte 5.0 / Kit 2.0 with the deltas called out inline. Where the rule cites a version (`$props.id()` 5.20+, `$app/state` Kit 2.12+, `reroute` hook Kit 2.3+, `paths.relative` default flip Kit 2.0, `cookies.path` mandatory Kit 2.0, `error()` / `redirect()` no-throw Kit 2.0), verify against the changelog for the version you have installed before adopting.

## License

MIT - see [LICENSE](LICENSE)

## Links

- [Svelte 5 release notes](https://svelte.dev/blog/svelte-5-is-alive)
- [SvelteKit 2 migration guide](https://svelte.dev/docs/kit/migrating-to-sveltekit-2)
- [Runes overview](https://svelte.dev/docs/svelte/what-are-runes)
- [bits-ui](https://www.bits-ui.com)
- [sveltekit-superforms](https://superforms.rocks)
- [Cursor Plugin Documentation](https://docs.cursor.com/plugins)
- [RoninForge](https://roninforge.org)
