import { readFile } from "node:fs/promises";
import { join } from "node:path";

type OgFont = {
  name: string;
  data: ArrayBuffer;
  weight: 600 | 800;
  style: "normal";
};

/** SIL Open Font License — safe for web and OG image generation. */
export const ogFontFamily = "Nunito";

let fontCache: OgFont[] | null = null;
let iconCache: string | null = null;

export async function getOgFonts(): Promise<OgFont[]> {
  if (fontCache) return fontCache;

  const [semibold, extrabold] = await Promise.all([
    readFile(join(process.cwd(), "public/fonts/Nunito-SemiBold.ttf")),
    readFile(join(process.cwd(), "public/fonts/Nunito-ExtraBold.ttf")),
  ]);

  fontCache = [
    { name: ogFontFamily, data: semibold.buffer, weight: 600, style: "normal" },
    { name: ogFontFamily, data: extrabold.buffer, weight: 800, style: "normal" },
  ];

  return fontCache;
}

export async function getAppIconDataUrl(): Promise<string> {
  if (iconCache) return iconCache;

  const icon = await readFile(join(process.cwd(), "public/resources/img/cronica/icon.png"));
  iconCache = `data:image/png;base64,${icon.toString("base64")}`;
  return iconCache;
}

export const ogSize = { width: 1200, height: 630 } as const;

export const ogColors = {
  background: "#f5f5f7",
  foreground: "#1d1d1f",
  muted: "#6e6e73",
  subtle: "#86868b",
  accent: "#0071e3",
} as const;
