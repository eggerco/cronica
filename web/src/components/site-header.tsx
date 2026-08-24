import Image from "next/image";
import Link from "next/link";

import { Button } from "@/components/ui/button";
import { siteConfig } from "@/lib/content";

export function SiteHeader() {
  return (
    <header className="sticky top-0 z-50 w-full border-b bg-background/80 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="mx-auto flex h-14 max-w-6xl items-center justify-between px-4 sm:px-6">
        <Link href="/" className="flex items-center gap-3">
          <Image
            src="/resources/img/cronica/icon.webp"
            alt=""
            width={28}
            height={28}
            className="rounded-md"
          />
          <span className="text-[17px] font-medium tracking-wide">{siteConfig.name}</span>
        </Link>

        <nav className="hidden items-center gap-6 md:flex">
          <Link
            href="/#features"
            className="text-sm text-muted-foreground transition-colors hover:text-foreground"
          >
            Features
          </Link>
          <Link
            href="/#platforms"
            className="text-sm text-muted-foreground transition-colors hover:text-foreground"
          >
            Platforms
          </Link>
          <Link
            href="/privacy"
            className="text-sm text-muted-foreground transition-colors hover:text-foreground"
          >
            Privacy
          </Link>
          <Button asChild size="sm">
            <a href={siteConfig.appStoreUrl}>Download</a>
          </Button>
        </nav>

        <Button asChild size="sm" className="md:hidden">
          <a href={siteConfig.appStoreUrl}>Download</a>
        </Button>
      </div>
    </header>
  );
}
