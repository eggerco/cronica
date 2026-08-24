import { ImageResponse } from "next/og";

import { getAppIconDataUrl, getOgFonts, ogColors, ogFontFamily, ogSize } from "@/lib/og-fonts";

export const alt = "Cronica — Movies & TV Watchlist";
export const size = ogSize;
export const contentType = "image/png";

export default async function Image() {
  const [fonts, iconSrc] = await Promise.all([getOgFonts(), getAppIconDataUrl()]);

  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "center",
          padding: "72px 80px",
          backgroundColor: ogColors.background,
          fontFamily: ogFontFamily,
        }}
      >
        <div style={{ display: "flex", alignItems: "center", marginBottom: 40 }}>
          <img src={iconSrc} alt="" width={112} height={112} style={{ borderRadius: 24, marginRight: 28 }} />
          <div style={{ display: "flex", flexDirection: "column" }}>
            <div style={{ fontSize: 72, fontWeight: 800, color: ogColors.foreground, lineHeight: 1 }}>
              Cronica
            </div>
            <div style={{ fontSize: 28, fontWeight: 600, color: ogColors.muted, marginTop: 8 }}>
              Movies &amp; TV Watchlist
            </div>
          </div>
        </div>
        <div style={{ fontSize: 44, fontWeight: 600, color: ogColors.foreground, lineHeight: 1.2 }}>
          Track what you watch. Never lose your place.
        </div>
        <div style={{ marginTop: 28, fontSize: 24, fontWeight: 600, color: ogColors.subtle }}>
          Release reminders · iCloud sync · Everywhere on Apple
        </div>
      </div>
    ),
    { ...ogSize, fonts },
  );
}
