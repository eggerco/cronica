import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { ExternalLink } from "lucide-react";

import { Button } from "@/components/ui/button";
import { PosterPlaceholder } from "@/components/poster-placeholder";
import { buildDetailsPageUrl, parseDetailsSearchParams } from "@/lib/details";
import { siteConfig } from "@/lib/content";

type PageProps = {
  searchParams: Promise<Record<string, string | string[] | undefined>>;
};

export const dynamic = "force-dynamic";

export async function generateMetadata({ searchParams }: PageProps): Promise<Metadata> {
  const params = await searchParams;
  const details = parseDetailsSearchParams(params);
  const pageUrl = buildDetailsPageUrl(details);

  if (!details.hasContent) {
    return {
      title: "Open in Cronica",
      description: "Open this movie or TV show in Cronica — your personal watchlist app.",
      alternates: { canonical: `${siteConfig.url}/details` },
      openGraph: {
        title: "Open in Cronica",
        description: "Your personal watchlist for movies and TV.",
        url: pageUrl,
      },
    };
  }

  const description = `Open ${details.title} in Cronica — your personal watchlist for movies and TV.`;

  return {
    title: details.title,
    description,
    alternates: { canonical: `${siteConfig.url}/details` },
    openGraph: {
      title: `${details.title} — Cronica`,
      description,
      url: pageUrl,
    },
    twitter: {
      card: "summary_large_image",
      title: `${details.title} — Cronica`,
      description,
    },
  };
}

export default async function DetailsPage({ searchParams }: PageProps) {
  const params = await searchParams;
  const details = parseDetailsSearchParams(params);

  return (
    <div className="site-gradient min-h-[calc(100vh-5rem)]">
      <section className="mx-auto max-w-lg px-4 py-16 sm:px-6 sm:py-24">
        <div className="glass overflow-hidden rounded-[2rem] shadow-[0_20px_60px_rgba(0,0,0,0.08)]">
          <div className="flex flex-col items-center px-6 pb-8 pt-10 text-center sm:px-10">
            <div className="relative mb-6 aspect-[2/3] w-44 overflow-hidden rounded-2xl bg-muted shadow-[0_16px_40px_rgba(0,0,0,0.12)] ring-1 ring-black/[0.06] sm:w-52">
              {details.hasPoster && details.posterUrl ? (
                <Image
                  src={details.posterUrl}
                  alt={`${details.title} poster`}
                  width={208}
                  height={312}
                  className="size-full object-cover"
                  priority
                  unoptimized
                />
              ) : (
                <PosterPlaceholder />
              )}
            </div>
            <h1 className="text-balance text-2xl font-bold tracking-tight sm:text-3xl">
              {details.hasContent ? details.title : "Open in Cronica"}
            </h1>
            {details.mediaTypeLabel && (
              <p className="mt-2 text-base text-muted-foreground">{details.mediaTypeLabel}</p>
            )}
            {!details.hasContent && (
              <p className="mt-3 max-w-sm text-base leading-relaxed text-muted-foreground">
                Your personal watchlist for movies and TV — with release reminders and iCloud sync.
              </p>
            )}
          </div>

          <div className="flex flex-col gap-3 border-t border-black/[0.06] bg-white/40 px-6 py-6 sm:px-10">
            <Button asChild size="lg" className="h-12 w-full rounded-full shadow-sm">
              <a href={details.deepLinkUrl}>
                {details.hasContent ? "Open in Cronica" : "Get Cronica on the App Store"}
              </a>
            </Button>

            {details.tmdbUrl && (
              <Button asChild size="lg" variant="outline" className="h-12 w-full rounded-full bg-white/70">
                <a href={details.tmdbUrl} target="_blank" rel="noreferrer">
                  <ExternalLink className="size-4" />
                  View on TMDB
                </a>
              </Button>
            )}

            {!details.hasContent && (
              <Button asChild size="lg" variant="ghost" className="h-12 w-full rounded-full">
                <Link href="/">Back to home</Link>
              </Button>
            )}
          </div>
        </div>

        {!details.hasContent && (
          <p className="mt-8 text-center text-xs text-muted-foreground">
            Share a link from Cronica with <code className="rounded-md bg-white/70 px-1.5 py-0.5">?id=</code>,{" "}
            <code className="rounded-md bg-white/70 px-1.5 py-0.5">title=</code>, and{" "}
            <code className="rounded-md bg-white/70 px-1.5 py-0.5">img=</code> parameters.
          </p>
        )}
      </section>
    </div>
  );
}
