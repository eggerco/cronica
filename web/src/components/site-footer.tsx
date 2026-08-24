import Link from "next/link";

import { siteConfig } from "@/lib/content";

const footerLinks = [
  { label: "Home", href: "/" },
  { label: "Features", href: "/#features" },
  { label: "Privacy", href: "/privacy" },
  { label: "X", href: "https://x.com/CronicaApp" },
  { label: "GitHub", href: siteConfig.githubUrl },
  { label: "Support", href: `mailto:${siteConfig.supportEmail}` },
];

export function SiteFooter() {
  return (
    <footer className="border-t border-black/[0.06] bg-white/50 backdrop-blur-sm">
      <div className="mx-auto max-w-6xl px-4 py-12 sm:px-6 sm:py-14">
        <nav className="mb-8 flex flex-wrap justify-center gap-x-6 gap-y-3 md:justify-start">
          {footerLinks.map((link) => (
            <Link
              key={link.label}
              href={link.href}
              className="text-sm text-muted-foreground transition-colors duration-300 hover:text-foreground"
            >
              {link.label}
            </Link>
          ))}
        </nav>

        <div className="space-y-3 border-t border-black/[0.06] pt-8 text-center text-xs leading-relaxed text-muted-foreground md:text-left">
          <p>
            Movie and TV data from{" "}
            <a
              href="https://www.themoviedb.org/"
              className="underline underline-offset-4 transition-colors hover:text-foreground"
            >
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
