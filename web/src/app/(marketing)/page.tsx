import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { ArrowRight, Github, Shield } from "lucide-react";

import { JsonLd } from "@/components/json-ld";
import { Button } from "@/components/ui/button";
import { features, platforms, siteConfig } from "@/lib/content";

export const metadata: Metadata = {
  alternates: { canonical: siteConfig.url },
};

export default function HomePage() {
  return (
    <div className="site-gradient">
      <JsonLd />

      {/* Hero */}
      <section className="relative overflow-hidden">
        <div className="pointer-events-none absolute inset-x-0 top-0 h-[520px] bg-[radial-gradient(ellipse_at_center,rgba(255,255,255,0.9),transparent_70%)]" />
        <div className="relative mx-auto max-w-6xl px-4 pb-20 pt-10 sm:px-6 sm:pb-28 sm:pt-14">
          <div className="grid items-center gap-14 lg:grid-cols-2 lg:gap-20">
            <div className="space-y-8 text-center lg:text-left">
              <p className="section-label animate-fade-up mx-auto lg:mx-0">Movies &amp; TV watchlist</p>
              <div className="animate-fade-up-delay space-y-5">
                <h1 className="text-balance text-4xl font-bold tracking-tight sm:text-5xl lg:text-[3.5rem] lg:leading-[1.06]">
                  Track what you watch.
                  <br />
                  <span className="text-muted-foreground">Never lose your place.</span>
                </h1>
                <p className="mx-auto max-w-lg text-lg leading-relaxed text-muted-foreground lg:mx-0 lg:text-xl">
                  A native watchlist for movies and TV — with release reminders and iCloud sync across
                  Apple devices.
                </p>
              </div>
              <div className="animate-fade-up-delay-2 flex flex-col items-center gap-4 sm:flex-row sm:justify-center lg:justify-start">
                <a
                  href={siteConfig.appStoreUrl}
                  className="transition-transform duration-300 ease-out hover:scale-[1.03] active:scale-[0.98]"
                >
                  <Image
                    src="/resources/img/cronica/AppStoreBadge.svg"
                    alt="Download on the App Store"
                    width={168}
                    height={52}
                    priority
                  />
                </a>
                <Button
                  asChild
                  variant="outline"
                  size="lg"
                  className="h-12 rounded-full border-black/10 bg-white/70 px-6 shadow-sm backdrop-blur-sm transition-all duration-300 hover:bg-white"
                >
                  <a href={siteConfig.githubUrl} target="_blank" rel="noreferrer">
                    <Github className="size-4" />
                    View on GitHub
                  </a>
                </Button>
              </div>
              <p className="animate-fade-up-delay-2 text-xs text-muted-foreground/80">
                Cronica is not a streaming service.
              </p>
            </div>

            <div className="flex justify-center lg:justify-end">
              <div className="animate-float relative w-[min(100%,300px)]">
                <div className="absolute -inset-8 rounded-[3rem] bg-[radial-gradient(circle,rgba(255,130,100,0.18),transparent_65%)] blur-2xl" />
                <div className="absolute -inset-2 rounded-[2.25rem] bg-gradient-to-b from-white/80 to-transparent" />
                <Image
                  src="/resources/img/screenshots/iPhone.webp"
                  alt="Cronica on iPhone showing Up Next and Upcoming watchlist"
                  width={300}
                  height={650}
                  priority
                  className="relative rounded-[2rem] shadow-[0_32px_64px_rgba(0,0,0,0.14),0_8px_20px_rgba(0,0,0,0.06)] ring-1 ring-black/[0.06]"
                />
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Features */}
      <section id="features" className="border-y border-black/[0.04] bg-white/40 py-24 sm:py-32">
        <div className="mx-auto max-w-6xl px-4 sm:px-6">
          <div className="mx-auto mb-16 max-w-2xl text-center">
            <p className="section-label mb-3">Features</p>
            <h2 className="text-balance text-3xl font-bold tracking-tight sm:text-4xl lg:text-5xl">
              Built for your watchlist
            </h2>
            <p className="mt-4 text-lg leading-relaxed text-muted-foreground">
              Everything you need to stay on top of movies and TV — natively on Apple platforms.
            </p>
          </div>
          <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
            {features.map((feature) => (
              <article key={feature.title} className="glass-card p-6">
                <div className="mb-5 flex size-11 items-center justify-center rounded-2xl bg-black/[0.04] text-foreground">
                  <feature.icon className="size-5" strokeWidth={1.75} />
                </div>
                <h3 className="text-lg font-semibold tracking-tight">{feature.title}</h3>
                <p className="mt-2 text-sm leading-relaxed text-muted-foreground">{feature.description}</p>
              </article>
            ))}
          </div>
        </div>
      </section>

      {/* Platforms */}
      <section id="platforms" className="py-24 sm:py-32">
        <div className="mx-auto max-w-6xl px-4 sm:px-6">
          <div className="mx-auto mb-14 max-w-2xl text-center">
            <p className="section-label mb-3">Platforms</p>
            <h2 className="text-balance text-3xl font-bold tracking-tight sm:text-4xl lg:text-5xl">
              One watchlist, every screen
            </h2>
            <p className="mt-4 text-lg leading-relaxed text-muted-foreground">
              Designed for the full Apple ecosystem — from iPhone to Vision Pro.
            </p>
          </div>
          <div className="flex flex-wrap justify-center gap-3">
            {platforms.map((platform) => (
              <div
                key={platform.name}
                className="flex items-center gap-2 rounded-full border border-black/[0.06] bg-white/70 px-4 py-2.5 text-sm font-medium shadow-sm backdrop-blur-sm transition-all duration-300 hover:border-black/[0.1] hover:bg-white hover:shadow-md"
              >
                <platform.icon className="size-4 text-muted-foreground" strokeWidth={1.75} />
                {platform.name}
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Privacy */}
      <section className="border-t border-black/[0.04] bg-white/40 py-24 sm:py-28">
        <div className="mx-auto max-w-2xl px-4 text-center sm:px-6">
          <div className="mx-auto mb-5 flex size-14 items-center justify-center rounded-2xl bg-black/[0.04] text-foreground">
            <Shield className="size-6" strokeWidth={1.75} />
          </div>
          <p className="section-label mb-3">Privacy</p>
          <h2 className="text-3xl font-bold tracking-tight sm:text-4xl">Privacy-first by design</h2>
          <p className="mt-4 text-lg leading-relaxed text-muted-foreground">
            No ads. No data selling. Your watchlist stays in your private iCloud account.
          </p>
          <Button asChild variant="link" className="mt-6 text-base">
            <Link href="/privacy">
              Read our privacy policy
              <ArrowRight className="size-4" />
            </Link>
          </Button>
        </div>
      </section>

      {/* Download CTA */}
      <section className="pb-24 pt-4 sm:pb-32">
        <div className="mx-auto max-w-3xl px-4 text-center sm:px-6">
          <div className="glass rounded-[2rem] px-6 py-12 shadow-[0_20px_60px_rgba(0,0,0,0.06)] sm:px-10 sm:py-14">
            <h2 className="text-balance text-2xl font-bold tracking-tight sm:text-3xl">
              Ready to pick up where you left off?
            </h2>
            <p className="mt-3 text-muted-foreground">Download Cronica free on the App Store.</p>
            <a
              href={siteConfig.appStoreUrl}
              className="mt-8 inline-block transition-transform duration-300 ease-out hover:scale-[1.03] active:scale-[0.98]"
            >
              <Image
                src="/resources/img/cronica/AppStoreBadge.svg"
                alt="Download on the App Store"
                width={168}
                height={52}
              />
            </a>
          </div>
        </div>
      </section>
    </div>
  );
}
