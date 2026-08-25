import { renderDetailsPage } from "./details";

interface Env {
  ASSETS: Fetcher;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    if (url.pathname === "/details" || url.pathname === "/details/") {
      return new Response(renderDetailsPage(url), {
        headers: {
          "content-type": "text/html; charset=utf-8",
          "cache-control": "no-store",
        },
      });
    }

    if (url.pathname === "/apple-app-site-association") {
      return Response.redirect(`${url.origin}/.well-known/apple-app-site-association`, 301);
    }

    return env.ASSETS.fetch(request);
  },
} satisfies ExportedHandler<Env>;
