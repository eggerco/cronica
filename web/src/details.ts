export const siteConfig = {
  name: "Cronica",
  description:
    "Track what you watch. Never lose your place. A watchlist for movies and TV with release reminders and iCloud sync across Apple devices.",
  url: "https://www.cronica.watch",
  appStoreUrl: "https://apps.apple.com/app/cronica/id1614950275",
  githubUrl: "https://github.com/eggerco/cronica",
  supportEmail: "support@cronica.watch",
  xUrl: "https://x.com/CronicaApp",
  ogImageUrl: "https://www.cronica.watch/assets/opengraph-image.png",
  ogImageWidth: 1024,
  ogImageHeight: 537,
  ogImageAlt: "Cronica — Track what you watch. Never lose your place.",
} as const;

export type DetailsParams = {
  id?: string;
  img?: string;
  title: string;
  mediaTypeLabel: string;
  tmdbUrl: string | null;
  posterUrl: string | null;
  deepLinkUrl: string;
  hasContent: boolean;
  hasPoster: boolean;
};

/** Decode until stable so legacy double-encoded share links still render cleanly. */
export function decodeQueryValue(raw: string): string {
  let current = raw.replace(/\+/g, " ");
  for (let i = 0; i < 3; i += 1) {
    try {
      const next = decodeURIComponent(current);
      if (next === current) break;
      current = next;
    } catch {
      break;
    }
  }
  return current.trim();
}

/** Fixes older shares that accidentally duplicated the title in the query value. */
export function collapseDuplicatedTitle(title: string): string {
  const trimmed = title.trim().replace(/\s+/g, " ");
  for (let i = 1; i < trimmed.length; i += 1) {
    if (trimmed[i] !== " ") continue;
    const left = trimmed.slice(0, i);
    const right = trimmed.slice(i + 1);
    if (left.length > 0 && left === right) {
      return left;
    }
  }
  return trimmed;
}

export function normalizeTitle(raw: string | null): string {
  if (!raw) return "Untitled";
  return collapseDuplicatedTitle(decodeQueryValue(raw));
}

export function posterImageUrl(img: string | null | undefined): string | null {
  if (!img) return null;
  const path = decodeQueryValue(img).replace(/^\/+/, "");
  if (!path) return null;
  return `https://image.tmdb.org/t/p/w780/${path}`;
}

export function parseDetailsSearchParams(searchParams: URLSearchParams): DetailsParams {
  const id = searchParams.get("id") ?? undefined;
  const imgRaw = searchParams.get("img") ?? undefined;
  const title = normalizeTitle(searchParams.get("title"));

  let mediaTypeLabel = "";
  let tmdbUrl: string | null = null;

  if (id) {
    const parts = id.split("@");
    if (parts.length >= 2 && (parts[1] === "0" || parts[1] === "1")) {
      const mediaType = parts[1] === "0" ? "movie" : "tv";
      mediaTypeLabel = parts[1] === "0" ? "Movie" : "TV Show";
      tmdbUrl = `https://www.themoviedb.org/${mediaType}/${parts[0]}`;
    }
  }

  const posterUrl = posterImageUrl(imgRaw);
  const deepLinkUrl = id ? `cronica://${id}` : siteConfig.appStoreUrl;

  return {
    id,
    img: imgRaw,
    title,
    mediaTypeLabel,
    tmdbUrl,
    posterUrl,
    deepLinkUrl,
    hasContent: Boolean(id),
    hasPoster: Boolean(posterUrl),
  };
}

export function buildDetailsPageUrl(details: {
  id: string;
  title: string;
  img?: string;
}): string {
  const params = new URLSearchParams();
  params.set("id", details.id);
  params.set("title", details.title);
  if (details.img) {
    params.set("img", details.img.replace(/^\/+/, ""));
  }
  return `${siteConfig.url}/details?${params.toString()}`;
}

function escapeHtml(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

export function renderDetailsPage(url: URL): string {
  const details = parseDetailsSearchParams(url.searchParams);
  const documentTitle = details.hasContent ? `${details.title} — Cronica` : "Open in Cronica";
  const socialTitle = details.hasContent ? details.title : "Cronica";
  const description = details.hasContent
    ? `Open ${details.title} in Cronica — your personal watchlist for movies and TV.`
    : siteConfig.description;
  const canonical = details.hasContent
    ? buildDetailsPageUrl({
        id: details.id!,
        title: details.title,
        img: details.img ? decodeQueryValue(details.img).replace(/^\/+/, "") : undefined,
      })
    : `${siteConfig.url}/details`;

  const posterMarkup =
    details.hasPoster && details.posterUrl
      ? `<img src="${escapeHtml(details.posterUrl)}" alt="${escapeHtml(details.title)} poster" class="details-poster" />`
      : `<div class="details-poster details-poster-placeholder" aria-hidden="true">
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="details-poster-icon" aria-hidden="true">
          <path d="M5 5a2 2 0 0 1 3.008-1.728l11.997 6.998a2 2 0 0 1 .003 3.458l-12 7A2 2 0 0 1 5 19z"/>
        </svg>
      </div>`;

  const primaryAction = details.hasContent
    ? `<a href="${escapeHtml(details.deepLinkUrl)}" class="button button-primary">Open in Cronica</a>`
    : `<a href="${siteConfig.appStoreUrl}" class="download-cta" aria-label="Download Cronica on the App Store"><img src="/assets/download.svg" alt="Download on the App Store" /></a>`;

  const tmdbAction = details.tmdbUrl
    ? `<a href="${escapeHtml(details.tmdbUrl)}" class="button button-secondary" target="_blank" rel="noreferrer">View on TMDB</a>`
    : "";

  const fallbackCopy = details.hasContent
    ? ""
    : `<p class="details-copy">Your personal watchlist for movies and TV — with release reminders and iCloud sync.</p>`;

  const hint = details.hasContent
    ? ""
    : `<p class="details-hint">Share a link from Cronica with <code>?id=</code>, <code>title=</code>, and <code>img=</code> parameters.</p>`;

  const ogImageUrl = details.posterUrl ?? siteConfig.ogImageUrl;
  const ogImageWidth = details.posterUrl ? 780 : siteConfig.ogImageWidth;
  const ogImageHeight = details.posterUrl ? 1170 : siteConfig.ogImageHeight;
  const ogImageAlt = details.posterUrl ? `${details.title} poster` : siteConfig.ogImageAlt;

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>${escapeHtml(documentTitle)}</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="description" content="${escapeHtml(description)}">
  <link rel="canonical" href="${escapeHtml(canonical)}">
  <meta property="og:title" content="${escapeHtml(socialTitle)}">
  <meta property="og:description" content="${escapeHtml(description)}">
  <meta property="og:url" content="${escapeHtml(canonical)}">
  <meta property="og:type" content="website">
  <meta property="og:site_name" content="Cronica">
  <meta property="og:image" content="${escapeHtml(ogImageUrl)}">
  <meta property="og:image:alt" content="${escapeHtml(ogImageAlt)}">
  <meta property="og:image:width" content="${ogImageWidth}">
  <meta property="og:image:height" content="${ogImageHeight}">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="${escapeHtml(socialTitle)}">
  <meta name="twitter:description" content="${escapeHtml(description)}">
  <meta name="twitter:image" content="${escapeHtml(ogImageUrl)}">
  <meta name="twitter:image:alt" content="${escapeHtml(ogImageAlt)}">
  <link rel="icon" type="image/png" sizes="32x32" href="/assets/favicon-32.png">
  <link rel="icon" type="image/png" sizes="16x16" href="/assets/favicon-16.png">
  <link rel="apple-touch-icon" sizes="180x180" href="/assets/favicon-180.png">
  <link rel="stylesheet" href="/style.css">
</head>
<body class="details-page">
  <header class="navbar">
    <div class="logo">
      <a href="/" class="logo-link">
        <img src="/assets/icon.png" alt="" class="logo-icon">
        <span class="logo-text">Cronica</span>
      </a>
    </div>
    <nav>
      <a href="/privacy/">Privacy</a>
      <a href="https://x.com/CronicaApp">X</a>
    </nav>
  </header>

  <main class="details-shell">
    <section class="details-card">
      ${posterMarkup}
      <h1>${escapeHtml(details.hasContent ? details.title : "Open in Cronica")}</h1>
      ${details.mediaTypeLabel ? `<p class="details-type">${escapeHtml(details.mediaTypeLabel)}</p>` : ""}
      ${fallbackCopy}
      <div class="details-actions">
        ${primaryAction}
        ${tmdbAction}
        ${details.hasContent ? "" : `<a href="/" class="button button-secondary">Back to home</a>`}
      </div>
    </section>
    ${hint}
  </main>

  <footer class="site-footer">
    <p>Copyright &copy; 2026 Egger, Inc. All rights reserved.</p>
  </footer>
</body>
</html>`;
}
