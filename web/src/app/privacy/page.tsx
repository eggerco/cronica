import type { Metadata } from "next";
import Link from "next/link";

import { Footer } from "@/components/footer";
import { siteConfig } from "@/lib/content";

export const metadata: Metadata = {
  title: "Privacy Policy",
  description: "Cronica privacy policy — how we handle your data in our privacy-focused watchlist app.",
  alternates: { canonical: `${siteConfig.url}/privacy` },
};

export default function PrivacyPage() {
  return (
    <>
      <article data-nav-theme="light" className="section-paper min-h-screen px-6 py-28 lg:px-10 lg:py-36">
        <div className="mx-auto max-w-3xl">
          <Link href="/" className="text-sm font-semibold text-coral hover:underline">
            ← Back home
          </Link>

          <p className="mt-10 text-xs font-bold uppercase tracking-[0.2em] text-coral">Legal</p>
          <h1 className="mt-4 text-4xl font-extrabold tracking-tight sm:text-5xl">Privacy Policy</h1>
          <p className="mt-3 text-sm text-muted">Last updated: August 24, 2026</p>

          <div className="prose-cronica mt-12 space-y-10 text-muted">
            <p>
              Welcome to Cronica. This Privacy Policy explains how we collect, use, and safeguard your
              information when you use our privacy-focused watchlist app.
            </p>

            <section className="space-y-4">
              <h2 className="text-xl font-bold text-ink">1. Introduction</h2>
              <p className="leading-relaxed">
                Cronica is a privacy-focused app that lets you track movies and TV shows. We collect
                minimal data to reduce crashes and improve the app. The data we collect is anonymous and
                cannot be traced back to you.
              </p>
            </section>

            <section className="space-y-4">
              <h2 className="text-xl font-bold text-ink">2. Data Collection</h2>
              <p className="leading-relaxed">
                <strong className="text-ink">No ads or data selling.</strong> We do not sell or rent your
                data to third parties, and the app contains no advertisements.
              </p>
              <p className="leading-relaxed">
                <strong className="text-ink">iCloud sync.</strong> By default, your data syncs with your
                private iCloud account. Your synced data remains safe and inaccessible to us as app
                developers.
              </p>
              <p className="leading-relaxed">
                <strong className="text-ink">Aptabase analytics.</strong> To minimize crashes and improve
                performance, we use Aptabase — a privacy-first analytics service. Information collected
                includes:
              </p>
              <ul className="list-disc space-y-2 pl-5 leading-relaxed">
                <li>Random user ID — active users and app version adoption</li>
                <li>Device type — iPhone, iPad, Mac, Apple Watch, Apple TV, or Vision Pro</li>
                <li>OS version and locale</li>
                <li>App version, build number, and relevant crash reports</li>
              </ul>
            </section>

            <section className="space-y-4">
              <h2 className="text-xl font-bold text-ink">3. Data Security</h2>
              <p className="leading-relaxed">
                Content data is provided by the TMDB API via secure HTTPS requests. Cronica is open source
                on{" "}
                <a href="https://github.com/eggerco/cronica" className="font-semibold text-ink underline">
                  GitHub
                </a>
                . API keys are not included in the public repository.
              </p>
            </section>

            <section className="space-y-4">
              <h2 className="text-xl font-bold text-ink">4. Contact</h2>
              <p className="leading-relaxed">
                Questions about this policy? Contact us at{" "}
                <a href="mailto:support@eggerco.com" className="font-semibold text-ink underline">
                  support@eggerco.com
                </a>
                .
              </p>
            </section>
          </div>
        </div>
      </article>
      <Footer />
    </>
  );
}
