import { ImageResponse } from "next/og";

import { parseDetailsSearchParams } from "@/lib/details";
import { getAppIconDataUrl, getOgFonts, ogColors, ogFontFamily, ogSize } from "@/lib/og-fonts";

export const alt = "Open in Cronica";
export const size = ogSize;
export const contentType = "image/png";
export const dynamic = "force-dynamic";

type ImageProps = {
  searchParams: Promise<Record<string, string | string[] | undefined>>;
};

export default async function Image({ searchParams }: ImageProps) {
  const params = await searchParams;
  const details = parseDetailsSearchParams(params);
  const [fonts, iconSrc] = await Promise.all([getOgFonts(), getAppIconDataUrl()]);
  const posterSrc = details.img ? `https://image.tmdb.org/t/p/w500/${details.img}` : null;

  if (!details.hasContent) {
    return new ImageResponse(
      (
        <div
          style={{
            width: "100%",
            height: "100%",
            display: "flex",
            flexDirection: "column",
            justifyContent: "center",
            alignItems: "center",
            padding: "72px 80px",
            backgroundColor: ogColors.background,
            fontFamily: ogFontFamily,
          }}
        >
          <img src={iconSrc} alt="" width={120} height={120} style={{ borderRadius: 28, marginBottom: 32 }} />
          <div style={{ fontSize: 56, fontWeight: 800, color: ogColors.foreground, lineHeight: 1.1 }}>
            Open in Cronica
          </div>
          <div
            style={{
              marginTop: 20,
              fontSize: 28,
              fontWeight: 600,
              color: ogColors.muted,
              textAlign: "center",
              maxWidth: 720,
            }}
          >
            Your personal watchlist for movies and TV
          </div>
        </div>
      ),
      { ...ogSize, fonts },
    );
  }

  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          alignItems: "center",
          padding: "64px 72px",
          backgroundColor: ogColors.background,
          fontFamily: ogFontFamily,
        }}
      >
        {posterSrc ? (
          <img
            src={posterSrc}
            alt=""
            width={320}
            height={480}
            style={{
              borderRadius: 24,
              objectFit: "cover",
              boxShadow: "0 24px 48px rgba(0, 0, 0, 0.12)",
            }}
          />
        ) : (
          <div
            style={{
              display: "flex",
              width: 320,
              height: 480,
              borderRadius: 24,
              background: "linear-gradient(180deg, #ececee 0%, #f5f5f7 100%)",
              boxShadow: "0 24px 48px rgba(0, 0, 0, 0.12)",
              alignItems: "center",
              justifyContent: "center",
            }}
          >
            <div
              style={{
                display: "flex",
                width: 72,
                height: 72,
                borderRadius: 20,
                backgroundColor: "rgba(255, 255, 255, 0.6)",
                border: "1px solid rgba(0, 0, 0, 0.08)",
                alignItems: "center",
                justifyContent: "center",
              }}
            >
              <svg
                width="36"
                height="36"
                viewBox="0 0 24 24"
                fill="none"
                stroke="#aeaeb2"
                strokeWidth="1.5"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <rect width="18" height="18" x="3" y="3" rx="2" />
                <path d="M7 3v18" />
                <path d="M3 7.5h4" />
                <path d="M3 12h18" />
                <path d="M3 16.5h4" />
                <path d="M17 3v18" />
                <path d="M17 7.5h4" />
                <path d="M17 16.5h4" />
              </svg>
            </div>
          </div>
        )}

        <div
          style={{
            display: "flex",
            flexDirection: "column",
            marginLeft: 56,
            flex: 1,
            minWidth: 0,
          }}
        >
          {details.mediaTypeLabel && (
            <div
              style={{
                alignSelf: "flex-start",
                fontSize: 20,
                fontWeight: 600,
                color: ogColors.muted,
                border: "2px solid rgba(0,0,0,0.08)",
                borderRadius: 999,
                padding: "8px 18px",
                marginBottom: 24,
              }}
            >
              {details.mediaTypeLabel}
            </div>
          )}

          <div
            style={{
              fontSize: details.title.length > 28 ? 52 : 64,
              fontWeight: 800,
              color: ogColors.foreground,
              lineHeight: 1.08,
              letterSpacing: "-0.02em",
            }}
          >
            {details.title}
          </div>

          <div style={{ marginTop: 24, fontSize: 30, fontWeight: 600, color: ogColors.muted }}>
            Open in Cronica
          </div>

          <div
            style={{
              marginTop: "auto",
              display: "flex",
              alignItems: "center",
              paddingTop: 48,
            }}
          >
            <img src={iconSrc} alt="" width={48} height={48} style={{ borderRadius: 12, marginRight: 16 }} />
            <div style={{ fontSize: 24, fontWeight: 700, color: ogColors.foreground }}>Cronica</div>
            <div style={{ fontSize: 22, fontWeight: 600, color: ogColors.subtle, marginLeft: 12 }}>
              Movies &amp; TV Watchlist
            </div>
          </div>
        </div>
      </div>
    ),
    { ...ogSize, fonts },
  );
}
