import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { ArrowRight, Github, Shield } from "lucide-react";

import { JsonLd } from "@/components/json-ld";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { features, platforms, siteConfig } from "@/lib/content";

export const metadata: Metadata = {
  alternates: { canonical: siteConfig.url },
};

export default function HomePage() {
  return (
    <>
      <JsonLd />
      {/* Hero */}
      <section className="mx-auto max-w-6xl px-4 pb-16 pt-12 sm:px-6 sm:pb-24 sm:pt-16">
        <div className="grid items-center gap-12 lg:grid-cols-2 lg:gap-16">
          <div className="space-y-6 text-center lg:text-left">
            <Badge variant="secondary" className="mx-auto lg:mx-0">
              Movies &amp; TV watchlist
            </Badge>
            <div className="space-y-4">
              <h1 className="text-4xl font-semibold tracking-tight sm:text-5xl lg:text-[3.25rem] lg:leading-[1.08]">
                Track what you watch.
                <br />
                Never lose your place.
              </h1>
              <p className="mx-auto max-w-lg text-lg text-muted-foreground lg:mx-0">
                A native watchlist for movies and TV — with release reminders and iCloud sync across
                Apple devices.
              </p>
            </div>
            <div className="flex flex-col items-center gap-3 sm:flex-row sm:justify-center lg:justify-start">
              <a href={siteConfig.appStoreUrl}>
                <Image
                  src="/resources/img/cronica/AppStoreBadge.svg"
                  alt="Download on the App Store"
                  width={156}
                  height={48}
                  priority
                />
              </a>
              <Button asChild variant="outline" size="lg">
                <a href={siteConfig.githubUrl} target="_blank" rel="noreferrer">
                  <Github />
                  View on GitHub
                </a>
              </Button>
            </div>
            <p className="text-xs text-muted-foreground">Cronica is not a streaming service.</p>
          </div>

          <div className="flex justify-center lg:justify-end">
            <div className="relative w-[min(100%,280px)]">
              <div className="absolute -inset-4 rounded-[2rem] bg-gradient-to-b from-muted to-transparent blur-2xl" />
              <Image
                src="/resources/img/screenshots/iPhone.webp"
                alt="Cronica on iPhone showing Up Next and Upcoming watchlist"
                width={300}
                height={650}
                priority
                className="relative rounded-[1.75rem] shadow-2xl ring-1 ring-border"
              />
            </div>
          </div>
        </div>
      </section>

      {/* Features */}
      <section id="features" className="border-y bg-muted/30 py-16 sm:py-24">
        <div className="mx-auto max-w-6xl px-4 sm:px-6">
          <div className="mx-auto mb-12 max-w-2xl text-center">
            <h2 className="text-3xl font-semibold tracking-tight sm:text-4xl">Built for your watchlist</h2>
            <p className="mt-3 text-muted-foreground">
              Everything you need to stay on top of movies and TV — natively on Apple platforms.
            </p>
          </div>
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {features.map((feature) => (
              <Card key={feature.title} className="border-border/60 bg-background/80 shadow-none">
                <CardHeader className="pb-2">
                  <div className="mb-2 flex size-10 items-center justify-center rounded-lg bg-primary/5 text-primary">
                    <feature.icon className="size-5" strokeWidth={1.75} />
                  </div>
                  <CardTitle className="text-base">{feature.title}</CardTitle>
                </CardHeader>
                <CardContent>
                  <CardDescription className="text-sm leading-relaxed">{feature.description}</CardDescription>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      </section>

      {/* Platforms */}
      <section id="platforms" className="py-16 sm:py-24">
        <div className="mx-auto max-w-6xl px-4 sm:px-6">
          <div className="mx-auto mb-10 max-w-2xl text-center">
            <h2 className="text-3xl font-semibold tracking-tight sm:text-4xl">One watchlist, every screen</h2>
            <p className="mt-3 text-muted-foreground">
              Designed for the full Apple ecosystem — from iPhone to Vision Pro.
            </p>
          </div>
          <div className="flex flex-wrap justify-center gap-2">
            {platforms.map((platform) => (
              <Badge key={platform.name} variant="outline" className="gap-1.5 px-3 py-1.5 text-sm">
                <platform.icon className="size-3.5" strokeWidth={1.75} />
                {platform.name}
              </Badge>
            ))}
          </div>
        </div>
      </section>

      {/* Privacy */}
      <section className="border-t bg-muted/30 py-16 sm:py-20">
        <div className="mx-auto max-w-2xl px-4 text-center sm:px-6">
          <div className="mx-auto mb-4 flex size-12 items-center justify-center rounded-full bg-primary/5 text-primary">
            <Shield className="size-5" strokeWidth={1.75} />
          </div>
          <h2 className="text-2xl font-semibold tracking-tight">Privacy-first by design</h2>
          <p className="mt-3 text-muted-foreground">
            No ads. No data selling. Your watchlist stays in your private iCloud account.
          </p>
          <Button asChild variant="link" className="mt-4">
            <Link href="/privacy">
              Read our privacy policy
              <ArrowRight className="size-4" />
            </Link>
          </Button>
        </div>
      </section>
    </>
  );
}
