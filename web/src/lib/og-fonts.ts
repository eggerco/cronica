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
  background: "#080808",
  foreground: "#ffffff",
  muted: "rgba(255,255,255,0.55)",
  subtle: "rgba(255,255,255,0.35)",
  accent: "#e85d3a",
} as const;
