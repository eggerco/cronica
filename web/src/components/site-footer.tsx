import Link from "next/link";

import { Separator } from "@/components/ui/separator";
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
    <footer className="border-t bg-muted/40">
      <div className="mx-auto max-w-6xl px-4 py-10 sm:px-6">
        <nav className="mb-6 flex flex-wrap justify-center gap-x-4 gap-y-2 md:justify-start">
          {footerLinks.map((link) => (
            <Link
              key={link.label}
              href={link.href}
              className="text-sm text-muted-foreground transition-colors hover:text-foreground"
            >
              {link.label}
            </Link>
          ))}
        </nav>

        <Separator className="mb-6" />

        <div className="space-y-2 text-center text-xs text-muted-foreground md:text-left">
          <p>
            Movie and TV data from{" "}
            <a href="https://www.themoviedb.org/" className="underline underline-offset-4">
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
