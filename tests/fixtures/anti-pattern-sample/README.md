# anti-pattern-sample

Negative fixture: every file violates at least one tracked Svelte 4 / SvelteKit 1 anti-pattern. The validate-plugin.sh script confirms the violations are present (so the rule list stays grounded in real code).

## Pinned versions on purpose

`svelte ^4.2.0` + `@sveltejs/kit ^1.27.0` + `lucide-svelte ^0.300.0` + `vitest ^0.34.0`. These are the last "Svelte 4 era" pins; the v3.3 / v3 / Vuex equivalent for the Svelte ecosystem.

## Tracked violations

| File                            | Anti-pattern numbers                        |
| ------------------------------- | ------------------------------------------- |
| `src/lib/Counter.svelte`        | #2, #3, #4, #6, #7, #30                     |
| `src/lib/stores.ts`             | #28, #29                                    |
| `src/routes/+page.svelte`       | #2, #3, #4, #5, #6, #7, #22                 |
| `src/routes/+page.server.ts`    | #17 (x2), #19 (x2), #20                     |

The grep audit in `tests/validation/validate-plugin.sh` counts these and asserts the total is at least 8.
