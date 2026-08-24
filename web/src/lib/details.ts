import { siteConfig } from "@/lib/content";

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

function getParam(
  searchParams: Record<string, string | string[] | undefined>,
  key: string,
): string | undefined {
  const value = searchParams[key];
  return typeof value === "string" ? value : undefined;
}

export function parseDetailsSearchParams(
  searchParams: Record<string, string | string[] | undefined> | undefined,
): DetailsParams {
  const id = getParam(searchParams ?? {}, "id");
  const img = getParam(searchParams ?? {}, "img");
  const title = getParam(searchParams ?? {}, "title") ?? "Untitled";

  let mediaTypeLabel = "";
  let tmdbUrl: string | null = null;

  if (id) {
    const parts = id.split("@");
    if (parts.length >= 2) {
      const mediaType = parts[1] === "0" ? "movie" : "tv";
      mediaTypeLabel = parts[1] === "0" ? "Movie" : "TV Show";
      tmdbUrl = `https://www.themoviedb.org/${mediaType}/${parts[0]}`;
    }
  }

  const posterUrl = img ? `https://image.tmdb.org/t/p/w780/${img}` : null;

  const deepLinkUrl = id ? `cronica://${id}` : siteConfig.appStoreUrl;

  return {
    id,
    img,
    title,
    mediaTypeLabel,
    tmdbUrl,
    posterUrl,
    deepLinkUrl,
    hasContent: Boolean(id),
    hasPoster: Boolean(img),
  };
}

export function buildDetailsPageUrl(details: Pick<DetailsParams, "id" | "title" | "img">): string {
  if (!details.id) return `${siteConfig.url}/details`;

  const params = new URLSearchParams({
    id: details.id,
    title: details.title,
  });

  if (details.img) params.set("img", details.img);

  return `${siteConfig.url}/details?${params.toString()}`;
}
