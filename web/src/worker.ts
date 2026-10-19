import { renderDetailsPage, siteConfig } from "./details";

interface Env {
  ASSETS: Fetcher;
}

const CANONICAL_HOST = "www.cronica.watch";

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    if (url.hostname === "cronica.watch") {
      url.hostname = CANONICAL_HOST;
      return Response.redirect(url.toString(), 301);
    }

    if (url.pathname === "/details" || url.pathname === "/details/") {
      return new Response(renderDetailsPage(url), {
        headers: {
          "content-type": "text/html; charset=utf-8",
          "cache-control": "no-store",
          // Baseline hardening: the page reflects query parameters (escaped),
          // so forbid framing, MIME sniffing and inline scripts as defense in depth.
          "content-security-policy":
            "default-src 'self'; img-src 'self' https://image.tmdb.org; script-src 'none'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'; form-action 'none'",
          "x-content-type-options": "nosniff",
          "referrer-policy": "strict-origin-when-cross-origin",
        },
      });
    }

    if (
      url.pathname === "/.well-known/apple-app-site-association" ||
      url.pathname === "/apple-app-site-association"
    ) {
      const assetURL = new URL(
        "/.well-known/apple-app-site-association",
        request.url
      );
      const assetResponse = await env.ASSETS.fetch(new Request(assetURL, request));
      if (!assetResponse.ok) {
        return assetResponse;
      }
      const body = await assetResponse.arrayBuffer();
      return new Response(body, {
        status: 200,
        headers: {
          "content-type": "application/json",
          "cache-control": "public, max-age=3600",
        },
      });
    }

    return env.ASSETS.fetch(request);
  },
} satisfies ExportedHandler<Env>;
