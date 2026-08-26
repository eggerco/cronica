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
        },
      });
    }

    if (url.pathname === "/apple-app-site-association") {
      return Response.redirect(`${siteConfig.url}/.well-known/apple-app-site-association`, 301);
    }

    return env.ASSETS.fetch(request);
  },
} satisfies ExportedHandler<Env>;
