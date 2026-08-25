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
          <p className="mt-3 text-sm text-muted">Last updated: August 25, 2026</p>

          <div className="prose-cronica mt-12 space-y-10 text-muted">
            <p>
              Welcome to Cronica. This Privacy Policy explains how we handle your information when you
              use our privacy-focused watchlist app. Cronica is designed to store your data on your device
              and in your private iCloud account — not on our servers.
            </p>

            <section className="space-y-4">
              <h2 className="text-xl font-bold text-ink">1. Who We Are</h2>
              <p className="leading-relaxed">
                Cronica is published by Egger &amp; Co. For privacy questions or data requests, contact{" "}
                <a href="mailto:support@eggerco.com" className="font-semibold text-ink underline">
                  support@eggerco.com
                </a>
                .
              </p>
            </section>

            <section className="space-y-4">
              <h2 className="text-xl font-bold text-ink">2. Data We Process</h2>
              <p className="leading-relaxed">
                <strong className="text-ink">No accounts.</strong> Cronica does not require sign-up. We do
                not operate user accounts or store your watchlist on our own servers.
              </p>
              <p className="leading-relaxed">
                <strong className="text-ink">Your watchlist data.</strong> Titles you save, episode
                progress, ratings, notes, custom lists, and app preferences are stored locally on your
                device. If iCloud sync is enabled, this data is stored in your private iCloud account via
                Apple CloudKit. We, as developers, cannot access your iCloud data.
              </p>
              <p className="leading-relaxed">
                <strong className="text-ink">Calendar and notifications.</strong> If you enable them,
                release reminders are scheduled on your device and optional release dates may be added to a
                dedicated &quot;Cronica&quot; calendar in your calendar app.
              </p>
              <p className="leading-relaxed">
                <strong className="text-ink">Crash diagnostics.</strong> In release builds, anonymous crash
                and error reports may be sent to Sentry to help us fix bugs. These reports do not include
                your watchlist content.
              </p>
              <p className="leading-relaxed">
                <strong className="text-ink">No ads or data selling.</strong> We do not sell or rent your
                data, and the app contains no advertisements.
              </p>
            </section>

            <section className="space-y-4">
              <h2 className="text-xl font-bold text-ink">3. Legal Basis (GDPR)</h2>
              <p className="leading-relaxed">
                Where EU/EEA/UK data protection law applies, we process data based on:
              </p>
              <ul className="list-disc space-y-2 pl-5 leading-relaxed">
                <li>
                  <strong className="text-ink">Contract / service delivery</strong> — to provide watchlist,
                  sync, notifications, and calendar features you choose to use
                </li>
                <li>
                  <strong className="text-ink">Legitimate interests</strong> — to maintain app stability
                  through anonymous crash reporting
                </li>
                <li>
                  <strong className="text-ink">Consent</strong> — where required for notifications,
                  calendar access, or optional features you enable in Settings
                </li>
              </ul>
            </section>

            <section className="space-y-4">
              <h2 className="text-xl font-bold text-ink">4. Your Rights</h2>
              <p className="leading-relaxed">
                Depending on your location, you may have the right to access, correct, delete, restrict, or
                object to processing of your personal data, and to data portability.
              </p>
              <p className="leading-relaxed">
                <strong className="text-ink">Delete your data in the app:</strong> Open{" "}
                <strong className="text-ink">Settings → Privacy &amp; Data → Delete My Data</strong>. This
                removes your watchlist, lists, progress, notifications, calendar events, and preferences
                from the device. If iCloud sync is enabled, deletions sync to your other Apple devices on
                the same iCloud account.
              </p>
              <p className="leading-relaxed">
                You can also remove iCloud data via Apple&apos;s system settings, and request removal of
                third-party crash reports by emailing{" "}
                <a href="mailto:support@eggerco.com" className="font-semibold text-ink underline">
                  support@eggerco.com
                </a>
                .
              </p>
            </section>

            <section className="space-y-4">
              <h2 className="text-xl font-bold text-ink">5. Data Retention</h2>
              <p className="leading-relaxed">
                Your watchlist data remains on your device and in your iCloud account until you delete it
                using the in-app deletion feature or remove the app/iCloud data. Cached images and network
                responses are temporary and can be cleared in Settings → Behavior → Clear Cache.
              </p>
            </section>

            <section className="space-y-4">
              <h2 className="text-xl font-bold text-ink">6. Data Security</h2>
              <p className="leading-relaxed">
                Content metadata is fetched from the TMDB API over HTTPS. Cronica is open source on{" "}
                <a href="https://github.com/eggerco/cronica" className="font-semibold text-ink underline">
                  GitHub
                </a>
                . API keys are not included in the public repository.
              </p>
            </section>

            <section className="space-y-4">
              <h2 className="text-xl font-bold text-ink">7. Contact</h2>
              <p className="leading-relaxed">
                Questions about this policy or your data? Contact us at{" "}
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
