"use client";

import Image from "next/image";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useState } from "react";

import { AppStoreButton } from "@/components/app-store-button";
import { siteConfig } from "@/lib/content";

const links = [
  { href: "/#features", label: "Features" },
  { href: "/#platforms", label: "Platforms" },
  { href: "/privacy", label: "Privacy" },
];

const PROBE_OFFSET = 80;

type NavTheme = "dark" | "light";

function getThemeFromSections(): NavTheme | null {
  const sections = document.querySelectorAll<HTMLElement>("[data-nav-theme]");
  if (!sections.length) return null;

  for (const section of sections) {
    const { top, bottom } = section.getBoundingClientRect();
    if (top <= PROBE_OFFSET && bottom > PROBE_OFFSET) {
      return section.dataset.navTheme === "light" ? "light" : "dark";
    }
  }

  const first = sections[0];
  if (first.getBoundingClientRect().top > PROBE_OFFSET) {
    return first.dataset.navTheme === "light" ? "light" : "dark";
  }

  const last = sections[sections.length - 1];
  if (last.getBoundingClientRect().bottom <= PROBE_OFFSET) {
    return last.dataset.navTheme === "light" ? "light" : "dark";
  }

  return null;
}

function getFallbackTheme(pathname: string): NavTheme {
  return pathname === "/privacy" ? "light" : "dark";
}

export function Nav() {
  const pathname = usePathname();
  const [theme, setTheme] = useState<NavTheme>(() => getFallbackTheme(pathname));
  const isLight = theme === "light";

  useEffect(() => {
    const update = () => {
      setTheme(getThemeFromSections() ?? getFallbackTheme(pathname));
    };

    update();
    window.addEventListener("scroll", update, { passive: true });
    window.addEventListener("resize", update);

    return () => {
      window.removeEventListener("scroll", update);
      window.removeEventListener("resize", update);
    };
  }, [pathname]);

  return (
    <header
      className={[
        "fixed inset-x-0 top-0 z-50 transition-colors duration-300",
        isLight ? "text-ink" : "text-white",
      ].join(" ")}
    >
      <div className="mx-auto flex max-w-7xl items-center justify-between px-6 py-5 lg:px-10">
        <Link href="/" className="group flex items-center gap-3">
          <Image
            src="/resources/img/cronica/icon.webp"
            alt=""
            width={36}
            height={36}
            className={[
              "rounded-[10px] transition-all duration-300 group-hover:scale-105",
              isLight ? "ring-1 ring-black/10" : "ring-1 ring-white/10",
            ].join(" ")}
          />
          <span className="text-lg font-bold tracking-tight transition-colors duration-300">
            {siteConfig.name}
          </span>
        </Link>

        <nav className="hidden items-center gap-10 md:flex">
          {links.map((link) => (
            <Link
              key={link.href}
              href={link.href}
              className={[
                "text-sm transition-colors duration-300",
                isLight ? "text-ink/60 hover:text-ink" : "text-white/60 hover:text-white",
              ].join(" ")}
            >
              {link.label}
            </Link>
          ))}
        </nav>

        <AppStoreButton
          label="Download"
          variant={isLight ? "ghost-dark" : "outline"}
          className="px-5 py-2.5 text-sm"
        />
      </div>
    </header>
  );
}
