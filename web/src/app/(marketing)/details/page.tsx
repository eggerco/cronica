import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";

import { AppStoreButton } from "@/components/app-store-button";
import { Footer } from "@/components/footer";
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
    <>
      <section data-nav-theme="dark" className="grain hero-glow flex min-h-screen items-center justify-center px-6 py-28">
        <div className="w-full max-w-md overflow-hidden rounded-3xl border border-white/10 bg-white/[0.03] shadow-[0_40px_80px_rgba(0,0,0,0.4)] backdrop-blur-sm">
          <div className="flex flex-col items-center px-8 pb-4 pt-10 text-center">
            <div className="relative mb-6 aspect-[2/3] w-44 overflow-hidden rounded-2xl shadow-[0_20px_50px_rgba(0,0,0,0.4)] ring-1 ring-white/10 sm:w-48">
              {details.hasPoster && details.posterUrl ? (
                <Image
                  src={details.posterUrl}
                  alt={`${details.title} poster`}
                  width={192}
                  height={288}
                  className="size-full object-cover"
                  priority
                  unoptimized
                />
              ) : (
                <PosterPlaceholder />
              )}
            </div>

            <h1 className="text-balance text-2xl font-extrabold tracking-tight sm:text-3xl">
              {details.hasContent ? details.title : "Open in Cronica"}
            </h1>
            {details.mediaTypeLabel && (
              <p className="mt-2 text-sm font-medium text-coral">{details.mediaTypeLabel}</p>
            )}
            {!details.hasContent && (
              <p className="mt-4 text-sm leading-relaxed text-white/50">
                Your personal watchlist for movies and TV — with release reminders and iCloud sync.
              </p>
            )}
          </div>

          <div className="flex flex-col gap-3 px-8 pb-8 pt-4">
            {details.hasContent ? (
              <a href={details.deepLinkUrl} className="btn btn-primary w-full">
                Open in Cronica
              </a>
            ) : (
              <AppStoreButton className="w-full" />
            )}

            {details.tmdbUrl && (
              <a
                href={details.tmdbUrl}
                target="_blank"
                rel="noreferrer"
                className="btn btn-outline w-full"
              >
                View on TMDB
              </a>
            )}

            {!details.hasContent && (
              <Link href="/" className="btn btn-outline w-full border-white/10 text-white/70">
                Back to home
              </Link>
            )}
          </div>
        </div>
      </section>

      {!details.hasContent && (
        <p className="-mt-16 pb-20 text-center text-xs text-white/35">
          Share a link from Cronica with{" "}
          <code className="rounded bg-white/10 px-1.5 py-0.5">?id=</code>,{" "}
          <code className="rounded bg-white/10 px-1.5 py-0.5">title=</code>, and{" "}
          <code className="rounded bg-white/10 px-1.5 py-0.5">img=</code> parameters.
        </p>
      )}

      <Footer />
    </>
  );
}
