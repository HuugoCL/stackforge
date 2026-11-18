// Cloudflare Pages - SUPORTE STACKFORGE
// Serves the public install.ps1 as PowerShell, never as HTML.
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.pathname === "/" || url.pathname === "/install.ps1") {
      if (request.method !== "GET" && request.method !== "HEAD") {
        return new Response("Method Not Allowed", { status: 405, headers: { Allow: "GET, HEAD" } });
      }
      const upstream = await fetch("https://raw.githubusercontent.com/HuugoCL/stackforge/main/install.ps1", {
        headers: { "Accept": "text/plain", "User-Agent": "stackforge-cloudflare-pages" },
        cf: { cacheTtl: 120, cacheEverything: true }
      });
      if (!upstream.ok) {
        return new Response("# SUPORTE STACKFORGE: instalador indisponivel. HTTP " + upstream.status + "\n", {
          status: 503, headers: { "Content-Type": "text/plain; charset=utf-8", "Cache-Control": "no-store" }
        });
      }
      return new Response(request.method === "HEAD" ? null : upstream.body, {
        status: 200,
        headers: {
          "Content-Type": "text/plain; charset=utf-8",
          "Cache-Control": "public, max-age=120",
          "X-Content-Type-Options": "nosniff"
        }
      });
    }
    return env.ASSETS.fetch(request);
  }
};
