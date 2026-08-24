import type { Metadata } from "next";

import { siteConfig } from "@/lib/content";

export const metadata: Metadata = {
  title: "Privacy Policy",
  description: "Cronica privacy policy — how we handle your data in our privacy-focused watchlist app.",
  alternates: { canonical: `${siteConfig.url}/privacy` },
};

export default function PrivacyPage() {
  return (
    <article className="mx-auto max-w-3xl px-4 py-12 sm:px-6 sm:py-16">
      <h1 className="text-3xl font-semibold tracking-tight">Privacy Policy</h1>
      <p className="mt-2 text-sm text-muted-foreground">Last updated: August 24, 2026</p>

      <div className="mt-8 space-y-8 text-muted-foreground">
        <p>
          Welcome to Cronica. This Privacy Policy explains how we collect, use, and safeguard your
          information when you use our privacy-focused watchlist app.
        </p>

        <section className="space-y-3">
          <h2 className="text-lg font-semibold text-foreground">1. Introduction</h2>
          <p>
            Cronica is a privacy-focused app that lets you track movies and TV shows. We collect
            minimal data to reduce crashes and improve the app. The data we collect is anonymous and
            cannot be traced back to you.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-semibold text-foreground">2. Data Collection</h2>
          <p>
            <strong className="text-foreground">No ads or data selling.</strong> We do not sell or
            rent your data to third parties, and the app contains no advertisements.
          </p>
          <p>
            <strong className="text-foreground">iCloud sync.</strong> By default, your data syncs with
            your private iCloud account. Your synced data remains safe and inaccessible to us as app
            developers.
          </p>
          <p>
            <strong className="text-foreground">Aptabase analytics.</strong> To minimize crashes and
            improve performance, we use Aptabase — a privacy-first analytics service. Information
            collected includes:
          </p>
          <ul className="list-disc space-y-1 pl-5">
            <li>Random user ID — active users and app version adoption</li>
            <li>Device type — iPhone, iPad, Mac, Apple Watch, Apple TV, or Vision Pro</li>
            <li>OS version and locale</li>
            <li>App version, build number, and relevant crash reports</li>
          </ul>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-semibold text-foreground">3. Data Security</h2>
          <p>
            Content data is provided by the TMDB API via secure HTTPS requests. Cronica is open
            source on{" "}
            <a href="https://github.com/eggerco/cronica" className="text-foreground underline">
              GitHub
            </a>
            . API keys are not included in the public repository.
          </p>
        </section>

        <section className="space-y-3">
          <h2 className="text-lg font-semibold text-foreground">4. Contact</h2>
          <p>
            Questions about this policy? Contact us at{" "}
            <a href="mailto:support@eggerco.com" className="text-foreground underline">
              support@eggerco.com
            </a>
            .
          </p>
        </section>
      </div>
    </article>
  );
}
