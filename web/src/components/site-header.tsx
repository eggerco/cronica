import Image from "next/image";
import Link from "next/link";

import { Button } from "@/components/ui/button";
import { siteConfig } from "@/lib/content";

export function SiteHeader() {
  return (
    <header className="sticky top-0 z-50 px-4 pt-4 sm:px-6">
      <div className="glass mx-auto flex h-14 max-w-6xl items-center justify-between rounded-2xl px-4 shadow-[0_8px_32px_rgba(0,0,0,0.04)] sm:px-5">
        <Link
          href="/"
          className="flex items-center gap-2.5 transition-opacity duration-300 hover:opacity-80"
        >
          <Image
            src="/resources/img/cronica/icon.webp"
            alt=""
            width={30}
            height={30}
            className="rounded-[9px] shadow-sm"
          />
          <span className="text-[17px] font-semibold tracking-tight">{siteConfig.name}</span>
        </Link>

        <nav className="hidden items-center gap-8 md:flex">
          <Link
            href="/#features"
            className="text-sm text-muted-foreground transition-colors duration-300 hover:text-foreground"
          >
            Features
          </Link>
          <Link
            href="/#platforms"
            className="text-sm text-muted-foreground transition-colors duration-300 hover:text-foreground"
          >
            Platforms
          </Link>
          <Link
            href="/privacy"
            className="text-sm text-muted-foreground transition-colors duration-300 hover:text-foreground"
          >
            Privacy
          </Link>
          <Button asChild size="sm" className="rounded-full px-5 shadow-sm">
            <a href={siteConfig.appStoreUrl}>Download</a>
          </Button>
        </nav>

        <Button asChild size="sm" className="rounded-full px-5 shadow-sm md:hidden">
          <a href={siteConfig.appStoreUrl}>Download</a>
        </Button>
      </div>
    </header>
  );
}
