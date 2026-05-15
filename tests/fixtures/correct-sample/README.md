# correct-sample

Gold-standard SvelteKit 2 + Svelte 5 (Runes) fixture. Every file follows the rules in `roninforge-sveltekit/rules/`.

## What it demonstrates

- **Runes everywhere**: `$state`, `$derived`, `$props`, `$bindable`, `$effect`, `$props.id()`.
- **DOM event attributes**: `onclick`, `oninput`, `onkeydown` (no `on:` namespace, no event modifiers).
- **Callback props** instead of `createEventDispatcher`.
- **Snippets** (`{@render children?.()}`) instead of `<slot>`.
- **`.svelte.ts` state module** for shared cart state.
- **`page` from `$app/state`** instead of `$page` from `$app/stores`.
- **`error()` / `redirect()`** called without `throw` (SvelteKit 2 form).
- **`cookies.set` / `cookies.delete`** with explicit `path: '/'`.
- **`satisfies PageLoad` / `Actions`** for full type inference.
- **`sveltekit-superforms` + `zod`** for the login form.
- **`reroute` hook** in `hooks.server.ts`.

## Running

This fixture is structural; it is not built or tested in CI. To wire it into a real project, run `pnpm install` and `pnpm svelte-check`.
