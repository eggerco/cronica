import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";

import { AppStoreButton } from "@/components/app-store-button";
import { Footer } from "@/components/footer";
import { JsonLd } from "@/components/json-ld";
import { features, platforms, siteConfig } from "@/lib/content";

export const metadata: Metadata = {
  alternates: { canonical: siteConfig.url },
};

export default function HomePage() {
  return (
    <>
      <JsonLd />

      {/* Hero */}
      <section data-nav-theme="dark" className="grain hero-glow relative min-h-screen overflow-hidden">
        <div className="relative mx-auto flex min-h-screen max-w-7xl flex-col px-6 pt-28 pb-20 lg:px-10 lg:pt-32">
          <div className="grid flex-1 items-center gap-16 lg:grid-cols-[1.1fr_0.9fr] lg:gap-8">
            <div className="max-w-xl">
              <p className="animate-rise mb-6 text-xs font-bold uppercase tracking-[0.2em] text-coral">
                Movies &amp; TV
              </p>
              <h1 className="animate-rise-delay text-balance text-[2.75rem] font-extrabold leading-[1.02] tracking-tight sm:text-6xl lg:text-[4.5rem]">
                <span className="headline-gradient">Track what you watch.</span>
                <br />
                <span className="accent-gradient">Never lose your place.</span>
              </h1>
              <p className="animate-rise-delay mt-7 text-lg leading-relaxed text-white/55 sm:text-xl">
                Native watchlist with release reminders and iCloud sync — built for iPhone, iPad, Mac,
                Watch, TV, and Vision Pro.
              </p>

              <div className="animate-rise-delay-2 mt-10 flex flex-wrap items-center gap-4">
                <AppStoreButton />
                <a href={siteConfig.githubUrl} target="_blank" rel="noreferrer" className="btn btn-outline">
                  <GitHubIcon />
                  Source on GitHub
                </a>
              </div>

              <p className="animate-rise-delay-2 mt-6 text-xs text-white/35">
                Cronica is not a streaming service.
              </p>
            </div>

            <div className="relative flex justify-center lg:justify-end">
              <div className="animate-float-slow relative w-[min(100%,340px)]">
                <div className="absolute -inset-16 rounded-full bg-[radial-gradient(circle,rgba(232,93,58,0.35),transparent_65%)] blur-3xl" />
                <Image
                  src="/resources/img/screenshots/iPhone.webp"
                  alt="Cronica on iPhone"
                  width={340}
                  height={737}
                  priority
                  className="relative rounded-[2.5rem] shadow-[0_50px_100px_rgba(0,0,0,0.55)] ring-1 ring-white/10"
                />
              </div>
            </div>
          </div>

          <div className="relative mt-20 grid grid-cols-3 gap-6 border-t border-white/10 pt-10 sm:gap-12">
            {[
              { stat: "6", label: "Apple platforms" },
              { stat: "100%", label: "Native SwiftUI" },
              { stat: "0", label: "Ads or tracking" },
            ].map((item) => (
              <div key={item.label}>
                <p className="text-3xl font-extrabold tracking-tight sm:text-4xl">{item.stat}</p>
                <p className="mt-1 text-xs text-white/45 sm:text-sm">{item.label}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Features */}
      <section id="features" data-nav-theme="light" className="section-paper">
        <div className="mx-auto max-w-7xl px-6 py-28 lg:px-10 lg:py-36">
          <div className="max-w-2xl">
            <p className="text-xs font-bold uppercase tracking-[0.2em] text-coral">Features</p>
            <h2 className="mt-4 text-4xl font-extrabold tracking-tight sm:text-5xl">
              Everything a watchlist should be
            </h2>
            <p className="mt-5 text-lg text-muted">
              No web wrapper. No ads. Just a fast, native app that keeps your list in sync.
            </p>
          </div>

          <div className="mt-20 divide-y divide-black/8">
            {features.map((feature, index) => (
              <article
                key={feature.title}
                className="group grid gap-6 py-10 sm:grid-cols-[4rem_1fr_1.5fr] sm:items-start sm:gap-10 sm:py-14"
              >
                <span className="text-sm font-bold tabular-nums text-coral">
                  {String(index + 1).padStart(2, "0")}
                </span>
                <div className="flex items-start gap-4">
                  <div className="flex size-11 shrink-0 items-center justify-center rounded-xl bg-ink/[0.04] text-ink transition-colors group-hover:bg-coral/10 group-hover:text-coral">
                    <feature.icon className="size-5" strokeWidth={1.75} />
                  </div>
                  <h3 className="pt-2 text-xl font-bold tracking-tight sm:text-2xl">{feature.title}</h3>
                </div>
                <p className="text-base leading-relaxed text-muted sm:pt-2">{feature.description}</p>
              </article>
            ))}
          </div>
        </div>
      </section>

      {/* Showcase */}
      <section data-nav-theme="dark" className="grain hero-glow relative overflow-hidden py-28 lg:py-36">
        <div className="relative mx-auto grid max-w-7xl items-center gap-16 px-6 lg:grid-cols-2 lg:gap-20 lg:px-10">
          <div>
            <p className="text-xs font-bold uppercase tracking-[0.2em] text-coral">Native</p>
            <h2 className="mt-4 text-balance text-4xl font-extrabold tracking-tight sm:text-5xl">
              Designed for Apple.
              <br />
              <span className="text-white/50">Not ported to it.</span>
            </h2>
            <p className="mt-6 max-w-md text-lg leading-relaxed text-white/55">
              SwiftUI on every platform. Core Data and CloudKit under the hood. Your watchlist feels
              at home whether you&apos;re on your phone, wrist, or in the living room.
            </p>
            <AppStoreButton className="mt-10" />
          </div>

          <div className="relative mx-auto w-[min(100%,300px)] lg:mx-0 lg:ml-auto">
            <div className="absolute -inset-12 rounded-full bg-[radial-gradient(circle,rgba(232,93,58,0.3),transparent_70%)] blur-3xl" />
            <Image
              src="/resources/img/screenshots/iPhone.webp"
              alt="Cronica watchlist"
              width={300}
              height={650}
              className="relative rounded-[2rem] shadow-[0_40px_80px_rgba(0,0,0,0.5)] ring-1 ring-white/10"
            />
          </div>
        </div>
      </section>

      {/* Platforms */}
      <section id="platforms" data-nav-theme="light" className="section-paper">
        <div className="mx-auto max-w-7xl px-6 py-28 lg:px-10 lg:py-36">
          <div className="text-center">
            <p className="text-xs font-bold uppercase tracking-[0.2em] text-coral">Platforms</p>
            <h2 className="mt-4 text-4xl font-extrabold tracking-tight sm:text-5xl">
              One list. Every screen.
            </h2>
          </div>

          <div className="mt-16 grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-6">
            {platforms.map((platform) => (
              <div
                key={platform.name}
                className="flex flex-col items-center gap-3 rounded-2xl border border-black/6 bg-white px-4 py-8 text-center transition-all duration-300 hover:-translate-y-1 hover:border-coral/30 hover:shadow-[0_20px_40px_rgba(232,93,58,0.08)]"
              >
                <platform.icon className="size-7 text-ink/70" strokeWidth={1.5} />
                <span className="text-sm font-semibold">{platform.name}</span>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Privacy */}
      <section data-nav-theme="dark" className="border-y border-white/10 py-28 lg:py-36">
        <div className="mx-auto max-w-3xl px-6 text-center lg:px-10">
          <p className="text-xs font-bold uppercase tracking-[0.2em] text-coral">Privacy</p>
          <h2 className="mt-4 text-4xl font-extrabold tracking-tight sm:text-5xl">
            Your data stays yours
          </h2>
          <p className="mt-6 text-lg leading-relaxed text-white/55">
            No ads. No data selling. Your watchlist lives in your private iCloud account — we
            can&apos;t read it.
          </p>
          <Link href="/privacy" className="btn btn-outline mt-10">
            Read privacy policy
            <ArrowIcon />
          </Link>
        </div>
      </section>

      {/* CTA */}
      <section data-nav-theme="light" className="section-paper">
        <div className="mx-auto max-w-7xl px-6 py-28 text-center lg:px-10 lg:py-36">
          <h2 className="text-balance text-4xl font-extrabold tracking-tight sm:text-5xl">
            Pick up where you left off
          </h2>
          <p className="mx-auto mt-5 max-w-md text-lg text-muted">
            Free on the App Store. Syncs across all your Apple devices.
          </p>
          <AppStoreButton variant="ghost-dark" className="mt-10" />
        </div>
      </section>

      <Footer />
    </>
  );
}

function GitHubIcon() {
  return (
    <svg viewBox="0 0 24 24" className="size-4 fill-current" aria-hidden>
      <path d="M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0024 12c0-6.63-5.37-12-12-12z" />
    </svg>
  );
}

function ArrowIcon() {
  return (
    <svg viewBox="0 0 16 16" className="size-4" fill="none" stroke="currentColor" strokeWidth="1.5" aria-hidden>
      <path d="M3 8h10M9 4l4 4-4 4" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}
