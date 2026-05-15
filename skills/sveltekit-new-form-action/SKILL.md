---
name: sveltekit-new-form-action
description: "Scaffold a SvelteKit 2 form action using sveltekit-superforms ^2.30 + formsnap ^2.0 + zod ^4.4 - one Zod schema; superValidate(zod(schema)) on the server load and the action; superForm(data.form, { validators: zodClient(schema) }) on the client; <Field> / <Control> / <Label> / <FieldErrors> from formsnap; use:enhance from $app/forms with the v2 callback args (formElement / formData NOT form / data); enctype='multipart/form-data' on file-input forms; fail(400, { form }) for validation failures; redirect / error called without throw; cookies with path: '/'. Refuses Felte, throw redirect, missing enctype, plain object returns from actions on validation failure. Pairs with the sveltekit-forms-and-actions and sveltekit-anti-patterns rules."
---

# Scaffold a New SvelteKit 2 Form Action

## When to use

Use when:

- Building a login / signup / contact / settings form in a SvelteKit 2 app.
- Migrating a Felte form to the documented Svelte 5 stack.
- A reviewer asked you to fix a `use:enhance` callback (`form` / `data` -> `formElement` / `formData`).

Target: `@sveltejs/kit ^2.60.1`, `sveltekit-superforms ^2.30.1`, `formsnap ^2.0.1`, `zod ^4.4.3`. The companion `sveltekit-forms-and-actions` and `sveltekit-anti-patterns` rules cover the surrounding patterns.

## Output

For a login route at `/login`, the scaffold writes three files.

### `src/routes/login/schema.ts`

```ts
import { z } from 'zod'

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8, 'Password must be at least 8 characters'),
})

export type LoginSchema = typeof loginSchema
```

### `src/routes/login/+page.server.ts`

```ts
import { fail, redirect } from '@sveltejs/kit'
import { superValidate, message } from 'sveltekit-superforms'
import { zod } from 'sveltekit-superforms/adapters'
import type { PageServerLoad, Actions } from './$types'
import { loginSchema } from './schema'

export const load: PageServerLoad = async ({ locals }) => {
  if (locals.user) redirect(303, '/dashboard')
  return { form: await superValidate(zod(loginSchema)) }
}

export const actions = {
  default: async ({ request, cookies, locals }) => {
    const form = await superValidate(request, zod(loginSchema))
    if (!form.valid) return fail(400, { form })

    const session = await locals.auth.signIn(form.data.email, form.data.password)
    if (!session) return message(form, 'Invalid credentials', { status: 401 })

    cookies.set('session', session.id, {
      path: '/',
      httpOnly: true,
      secure: true,
      sameSite: 'lax',
      maxAge: 60 * 60 * 24 * 7,
    })
    redirect(303, '/dashboard')
  },
} satisfies Actions
```

### `src/routes/login/+page.svelte`

```svelte
<script lang="ts">
  import { superForm } from 'sveltekit-superforms'
  import { zodClient } from 'sveltekit-superforms/adapters'
  import { Field, Control, Label, FieldErrors } from 'formsnap'
  import { loginSchema } from './schema'
  import type { PageData } from './$types'

  let { data }: { data: PageData } = $props()

  const sf = superForm(data.form, {
    validators: zodClient(loginSchema),
    resetForm: false,
  })
  const { form, errors, message: msg, enhance, submitting } = sf
</script>

<h1>Sign in</h1>

{#if $msg}<p class="error">{$msg}</p>{/if}

<form method="POST" use:enhance>
  <Field form={sf} name="email">
    <Control>
      {#snippet children({ props })}
        <Label>Email</Label>
        <input {...props} type="email" autocomplete="email" bind:value={$form.email} />
      {/snippet}
    </Control>
    <FieldErrors />
  </Field>

  <Field form={sf} name="password">
    <Control>
      {#snippet children({ props })}
        <Label>Password</Label>
        <input {...props} type="password" autocomplete="current-password" bind:value={$form.password} />
      {/snippet}
    </Control>
    <FieldErrors />
  </Field>

  <button type="submit" disabled={$submitting}>
    {$submitting ? 'Signing in.' : 'Sign in'}
  </button>
</form>
```

## Rules baked into the scaffold

1. **Single Zod schema** as the source of truth (server validation, client validation, error messages, types).
2. **`superValidate(zod(schema))`** on both `load` (initial blank form) and the action (incoming form).
3. **`fail(400, { form })`** for validation failures so the response status reflects the outcome.
4. **`message(form, 'text', { status })`** for action-level messages (e.g. "Invalid credentials").
5. **`redirect()` and `error()` called WITHOUT `throw`.** v2 made the helpers throw internally. (anti-pattern #17)
6. **`cookies.set` / `cookies.delete` always pass `{ path: '/', ... }`.** (anti-pattern #19)
7. **`use:enhance` from `$app/forms`.** The default progressive enhancement; superForm's `enhance` wraps it.
8. **v2 callback arg names (`formElement`, `formData`)** if you handle `enhance` callbacks directly. (anti-pattern #24)
9. **`enctype="multipart/form-data"`** on any form with file inputs. (anti-pattern #25)
10. **`actions` typed `satisfies Actions`** for type inference into `+page.svelte`'s `form` prop.

## Workflow

1. **Define the schema.** Put it in a sibling `schema.ts` so both `+page.server.ts` and `+page.svelte` can import it.
2. **Wire `+page.server.ts`.** `load` returns `{ form: await superValidate(zod(schema)) }`. The action validates the incoming request the same way.
3. **Wire `+page.svelte`.** `superForm(data.form, { validators: zodClient(schema) })` returns the bag (`form`, `errors`, `enhance`, `submitting`, `message`).
4. **Build inputs with `formsnap`.** `<Field>` / `<Control>` / `<Label>` / `<FieldErrors>` snippets give you accessible, error-aware fields.
5. **Handle outcomes.** `fail()` for validation errors; `message()` for app-level errors; `redirect()` for success.

## Examples

### File upload with `enctype`

```svelte
<form method="POST" enctype="multipart/form-data" use:enhance>
  <Field form={sf} name="avatar">
    <Control>
      {#snippet children({ props })}
        <Label>Avatar</Label>
        <input {...props} type="file" accept="image/*" />
      {/snippet}
    </Control>
    <FieldErrors />
  </Field>
  <button>Upload</button>
</form>
```

```ts
// +page.server.ts
const schema = z.object({
  avatar: z.instanceof(File).refine(f => f.size < 2_000_000, 'Max 2 MB'),
})
```

### Direct `use:enhance` (without superforms)

If you do not need superforms, you can still call `enhance` directly. Mind the v2 callback arg names.

```svelte
<script lang="ts">
  import { enhance } from '$app/forms'
  let submitting = $state(false)
</script>

<form
  method="POST"
  use:enhance={({ formElement, formData, action, cancel }) => {
    submitting = true
    return async ({ result, update }) => {
      submitting = false
      await update()
    }
  }}
>
  <input name="email" type="email" required />
  <button disabled={submitting}>Submit</button>
</form>
```

### Named action

```ts
export const actions = {
  login: async (event) => { /* ... */ },
  logout: async ({ cookies }) => {
    cookies.delete('session', { path: '/' })
    redirect(303, '/login')
  },
} satisfies Actions
```

```svelte
<form method="POST" action="?/login" use:enhance>...</form>
<form method="POST" action="?/logout" use:enhance><button>Log out</button></form>
```

## Common mistakes the scaffold refuses

- **`throw redirect(303, '/dashboard')`**. (anti-pattern #17)
- **`cookies.set('session', token, { httpOnly: true })` without `path`**. (anti-pattern #19)
- **`use:enhance={({ form, data }) => ...}`**. (anti-pattern #24)
- **File input form without `enctype="multipart/form-data"`**. (anti-pattern #25)
- **`createForm` from `felte`**. (anti-pattern #32)
- **Returning a bare object `{ error: 'x' }` from a validation failure** instead of `fail(400, { form })`.

## What this skill does NOT scaffold

- The corresponding REST endpoint. Use `/sveltekit-new-route` and add a `+server.ts`.
- A multi-step wizard. Build it with `superForm`'s `dataType: 'json'` mode.
- Server-side rate limiting. Add it in `src/hooks.server.ts`.
