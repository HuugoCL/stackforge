// Cloudflare Pages Functions (Advanced Mode): static assets live in /public.
// The installer response is sourced from this repository's main branch.
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;

    if (path === "/sup" || path === "/sup/") {
      if (request.method !== "GET" && request.method !== "HEAD") {
        return new Response("Method Not Allowed", { status: 405, headers: { Allow: "GET, HEAD" } });
      }
      try {
        const upstream = await fetch("https://raw.githubusercontent.com/HuugoCL/stackforge/main/install.ps1", {
          headers: { Accept: "text/plain", "User-Agent": "stackforge-cloudflare-pages" },
          cf: { cacheTtl: 60, cacheEverything: true }
        });
        if (!upstream.ok) throw new Error(`GitHub respondeu HTTP ${upstream.status}`);
        return new Response(request.method === "HEAD" ? null : upstream.body, {
          status: 200,
          headers: {
            "Content-Type": "text/plain; charset=utf-8",
            "Cache-Control": "public, max-age=60",
            "X-Content-Type-Options": "nosniff"
          }
        });
      } catch (error) {
        return new Response(`# SUPORTE STACKFORGE: instalador temporariamente indisponivel. ${error.message}\n`, {
          status: 503,
          headers: { "Content-Type": "text/plain; charset=utf-8", "Cache-Control": "no-store", "X-Content-Type-Options": "nosniff" }
        });
      }
    }

    return env.ASSETS.fetch(request);
  }
};
