// GOLD STANDARD:
// - .svelte.ts state module: shared reactive state via $state inside a class.
// - No `writable()` / `readable()` from svelte/store.
// - Mutate through the proxy (`this.items.push`); never destructure.

export type Item = {
  id: string
  name: string
  price: number
  quantity: number
}

class Cart {
  items = $state<Item[]>([])

  get total(): number {
    return this.items.reduce((sum, i) => sum + i.price * i.quantity, 0)
  }

  get count(): number {
    return this.items.reduce((sum, i) => sum + i.quantity, 0)
  }

  add(item: Omit<Item, 'quantity'>): void {
    const existing = this.items.find((i) => i.id === item.id)
    if (existing) {
      existing.quantity += 1
    } else {
      this.items.push({ ...item, quantity: 1 })
    }
  }

  remove(id: string): void {
    const idx = this.items.findIndex((i) => i.id === id)
    if (idx >= 0) this.items.splice(idx, 1)
  }

  clear(): void {
    this.items.length = 0
  }
}

export const cart = new Cart()
