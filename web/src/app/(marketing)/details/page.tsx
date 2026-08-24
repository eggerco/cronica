import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { ExternalLink } from "lucide-react";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader } from "@/components/ui/card";
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
    <section className="mx-auto max-w-lg px-4 py-12 sm:px-6 sm:py-16">
      <Card className="overflow-hidden border-border/60 bg-background/80 shadow-lg">
        <CardHeader className="items-center pb-0 text-center">
          <div className="relative mx-auto mb-4 aspect-[2/3] w-44 overflow-hidden rounded-xl bg-muted shadow-md ring-1 ring-border sm:w-52">
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
          <h1 className="text-2xl font-semibold tracking-tight sm:text-3xl">
            {details.hasContent ? details.title : "Open in Cronica"}
          </h1>
          {details.mediaTypeLabel && (
            <CardDescription className="text-base">{details.mediaTypeLabel}</CardDescription>
          )}
          {!details.hasContent && (
            <CardDescription className="text-base">
              Your personal watchlist for movies and TV — with release reminders and iCloud sync.
            </CardDescription>
          )}
        </CardHeader>

        <CardContent className="flex flex-col gap-3 pt-6">
          <Button asChild size="lg" className="w-full">
            <a href={details.deepLinkUrl}>
              {details.hasContent ? "Open in Cronica" : "Get Cronica on the App Store"}
            </a>
          </Button>

          {details.tmdbUrl && (
            <Button asChild size="lg" variant="outline" className="w-full">
              <a href={details.tmdbUrl} target="_blank" rel="noreferrer">
                <ExternalLink className="size-4" />
                View on TMDB
              </a>
            </Button>
          )}

          {!details.hasContent && (
            <Button asChild size="lg" variant="ghost" className="w-full">
              <Link href="/">Back to home</Link>
            </Button>
          )}
        </CardContent>
      </Card>

      {!details.hasContent && (
        <p className="mt-6 text-center text-xs text-muted-foreground">
          Share a link from Cronica with <code className="rounded bg-muted px-1 py-0.5">?id=</code>,{" "}
          <code className="rounded bg-muted px-1 py-0.5">title=</code>, and{" "}
          <code className="rounded bg-muted px-1 py-0.5">img=</code> parameters.
        </p>
      )}
    </section>
  );
}
