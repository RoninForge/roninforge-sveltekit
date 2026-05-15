// Universal hooks. Run on BOTH server and client. Lives in src/hooks.ts (NOT hooks.server.ts).
// `reroute` rewrites the URL used for route matching without changing the displayed path.
// Source: https://svelte.dev/docs/kit/hooks#Universal-hooks-reroute
import type { Reroute } from '@sveltejs/kit'

export const reroute: Reroute = ({ url }) => {
  if (url.pathname === '/about-us') return '/about'
}
