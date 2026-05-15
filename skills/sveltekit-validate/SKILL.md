---
name: sveltekit-validate
description: "Run the SvelteKit 2 + Svelte 5 plugin validation suite: tests/validation/validate-plugin.sh checks plugin manifest + rule frontmatter + skill frontmatter + correct-sample is free of banned Svelte 4 / SvelteKit 1 patterns + anti-pattern-sample contains the expected violations. Then run svelte-check (or pnpm svelte-check) for type errors, vitest for unit tests (pool: 'forks' default in v4), and playwright for E2E. Greps for tracked anti-patterns the type checker won't catch (on:click, $:, export let, <slot>, createEventDispatcher, throw redirect, throw error, cookies without path, $page from $app/stores, lucide-svelte, mount(App) in tests). Pairs with the sveltekit-anti-patterns rule and the sveltekit-reviewer agent."
---

# Validate the SvelteKit Plugin and Codebase

## When to use

Use when:

- You finished editing rules / skills / fixtures and need a clean structural check.
- You want to confirm a project under review has no tracked Svelte 4 / SvelteKit 1 anti-patterns.
- The reviewer agent flagged warnings and you want a fast structural re-check.

## Output

The skill is a procedure, not a code generator. Run the steps below in order.

### Step 1: structural validator

```bash
./tests/validation/validate-plugin.sh
```

Exits 0 on success. The script checks:

- `.cursor-plugin/plugin.json` is valid JSON with `name`, `version`, `description`, `author`, `license`.
- Each `rules/*.mdc` opens with YAML frontmatter (leading `---`) declaring `description` and `globs`.
- Each `skills/*/SKILL.md` has YAML frontmatter with `name` (matching the directory) and `description`.
- Each `agents/*.md` has YAML frontmatter with `name` and `description`.
- `correct-sample` is free of banned patterns (`on:click`, `$:` reactive statements, `export let`, `<slot>`, `createEventDispatcher`, `throw redirect`, `throw error`, `cookies.set` without `path`, `from '$app/stores'`).
- `anti-pattern-sample` contains those patterns (negative test: confirms the fixtures are realistic).
- `package.json` in `correct-sample` uses the right pinned versions.
- No em dashes (U+2014) anywhere.
- No emojis in any rule / skill / README.

### Step 2: type-check

```bash
pnpm svelte-check
```

Should exit 0 with `0 errors and 0 warnings` for the `correct-sample` fixture.

### Step 3: unit + component tests

```bash
pnpm vitest run
```

Runs all `*.test.ts` files. Vitest 4 default `pool` is `forks`; declare it explicitly in `vitest.config.ts`.

### Step 4: E2E tests

```bash
pnpm exec playwright test
```

Runs `e2e/*.spec.ts` against the built preview server.

### Step 5: grep audit (catch what the type checker misses)

```bash
# These should all return nothing in a clean SvelteKit 2 + Svelte 5 codebase:
grep -rEn "on:[a-z]+=" src/                                 # anti-pattern #4
grep -rEn "^\s*\\\$:[^=]" src/                              # anti-pattern #2
grep -rEn "^\s*export let " src/                            # anti-pattern #3
grep -rEn "<slot ?[/>]|<slot name=" src/                    # anti-pattern #7
grep -rEn "createEventDispatcher" src/                      # anti-pattern #6
grep -rEn "from '\$app/stores'" src/                        # anti-pattern #22
grep -rEn "throw (redirect|error)\(" src/                   # anti-pattern #17
grep -rEn "cookies\.(set|delete)\(" src/ | grep -v "path:"  # anti-pattern #19
grep -rEn "from 'lucide-svelte'" src/                       # anti-pattern #30
grep -rEn "from '@melt-ui/svelte'" src/                     # anti-pattern #31
grep -rEn "from 'felte'|from '@felte/" src/                 # anti-pattern #32
grep -rEn "new App\(\{" src/                                # anti-pattern #8 / #40
```

## Workflow

1. **Run the structural validator first.** Catches plugin shape issues before you waste time on the type checker.
2. **Run `svelte-check`.** Surfaces the runes / SvelteKit 2 type errors the validator can't catch.
3. **Run `vitest`.** Ensures unit tests pass. If a test file uses `mount(App)` or `new App({ target })`, fix it now.
4. **Run `playwright`.** Ensures E2E tests pass against the production-like preview server.
5. **Run the grep audit.** Catches the syntactic anti-patterns that compile but are wrong-by-convention.
6. **If the reviewer agent flagged WARN-or-higher findings**, fix them, then loop back to step 2.

## Examples

### Validating the plugin itself

From the repo root:

```bash
./tests/validation/validate-plugin.sh
```

Expected output ends with:

```
ALL CHECKS PASSED
```

Exit code 0.

### Validating a downstream SvelteKit 2 project

```bash
cd ~/your-svelte-project
pnpm install
pnpm svelte-check
pnpm vitest run
pnpm exec playwright test

# Then the grep audit:
grep -rEn "on:[a-z]+=" src/
grep -rEn "from '\$app/stores'" src/
grep -rEn "throw (redirect|error)\(" src/
```

If the grep returns hits, the codebase has tracked anti-patterns. Run the `sveltekit-reviewer` agent on the offending files for severity-grouped fix suggestions, or run the `/sveltekit-migrate-to-runes` skill for a stage-by-stage migration.

## Common mistakes

- **Running `svelte-check` before `pnpm install`.** The generated `$types` files do not exist yet.
- **Skipping the structural validator** because "the rules look fine." The validator checks frontmatter shape, version pins, and that the anti-pattern fixture still contains every banned pattern the rules reference.
- **Treating Vitest WARN about default pool as harmless.** It signals a v3 -> v4 default change; declare `pool: 'forks'` to lock the contract.
- **Running `playwright test` without first running `pnpm build`.** The default config in this skill builds-then-previews, but a custom `playwright.config.ts` may not.
