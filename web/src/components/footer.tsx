import Link from "next/link";

import { siteConfig } from "@/lib/content";

const links = [
  { label: "Home", href: "/" },
  { label: "Features", href: "/#features" },
  { label: "Privacy", href: "/privacy" },
  { label: "X", href: "https://x.com/CronicaApp" },
  { label: "GitHub", href: siteConfig.githubUrl },
  { label: "Support", href: `mailto:${siteConfig.supportEmail}` },
];

export function Footer() {
  return (
    <footer data-nav-theme="dark" className="border-t border-white/10 bg-ink">
      <div className="mx-auto max-w-7xl px-6 py-16 lg:px-10">
        <div className="flex flex-col gap-10 md:flex-row md:items-start md:justify-between">
          <div>
            <p className="text-2xl font-bold tracking-tight">{siteConfig.name}</p>
            <p className="mt-2 max-w-xs text-sm leading-relaxed text-white/50">
              A native watchlist for movies and TV across the Apple ecosystem.
            </p>
          </div>

          <nav className="flex flex-wrap gap-x-8 gap-y-3">
            {links.map((link) => (
              <Link
                key={link.label}
                href={link.href}
                className="text-sm text-white/50 transition-colors hover:text-white"
              >
                {link.label}
              </Link>
            ))}
          </nav>
        </div>

        <div className="divider-light mt-12" />

        <div className="mt-8 space-y-2 text-xs leading-relaxed text-white/40">
          <p>
            Movie and TV data from{" "}
            <a href="https://www.themoviedb.org/" className="underline hover:text-white/70">
              TMDB
            </a>
            . This product uses the TMDB API but is not endorsed or certified by TMDB.
          </p>
          <p>Copyright © 2026 Egger, Inc. All rights reserved.</p>
        </div>
      </div>
    </footer>
  );
}
