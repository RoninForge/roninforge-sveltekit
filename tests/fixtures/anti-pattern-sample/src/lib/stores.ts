// ANTI-PATTERN FIXTURE:
// - writable() store for what should be component-local state (anti-pattern #28)
// - .ts module (not .svelte.ts) for shared state (anti-pattern #29)

import { writable } from 'svelte/store'

export const cart = writable<{ items: { id: string; price: number }[] }>({ items: [] })
export const userName = writable<string>('')
