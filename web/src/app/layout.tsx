import type { Metadata } from "next";
import { Nunito } from "next/font/google";

import { Nav } from "@/components/nav";
import { siteConfig } from "@/lib/content";

import "./globals.css";

const nunito = Nunito({
  subsets: ["latin"],
  weight: ["400", "500", "600", "700", "800"],
  variable: "--font-nunito",
  display: "swap",
});

export const metadata: Metadata = {
  metadataBase: new URL(siteConfig.url),
  title: {
    default: `${siteConfig.name} — Movies & TV Watchlist`,
    template: `%s — ${siteConfig.name}`,
  },
  description: siteConfig.description,
  icons: {
    icon: "/resources/img/cronica/favicon.webp",
    apple: "/resources/img/cronica/icon.webp",
  },
  openGraph: {
    type: "website",
    url: siteConfig.url,
    siteName: siteConfig.name,
    title: `${siteConfig.name} — Movies & TV Watchlist`,
    description: siteConfig.description,
  },
  twitter: {
    card: "summary_large_image",
    title: `${siteConfig.name} — Movies & TV Watchlist`,
    description: siteConfig.description,
  },
  other: {
    "apple-itunes-app": "app-id=1614950275",
  },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body className={`${nunito.variable} min-h-screen font-sans antialiased`}>
        <Nav />
        {children}
      </body>
    </html>
  );
}
