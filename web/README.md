# Cronica Website

Marketing site and universal link handler for [Cronica](https://apps.apple.com/app/cronica/id1614950275).

Part of the [eggerco/cronica](https://github.com/eggerco/cronica) monorepo. Built with **Next.js** and **Tailwind CSS**.

**Live:** [cronica.eggerco.com](https://cronica.eggerco.com)

## Development

From this directory (`web/`):

```bash
npm install
npm run dev
npm run lint
```

## Build

```bash
npm run build    # production build
npm run preview  # build + next start locally
```

## Deploy (Vercel)

1. Connect the **eggerco/cronica** repo in [Vercel](https://vercel.com)
2. Set **Root Directory** to `web`
3. Framework preset: **Next.js** (auto-detected)
4. Build command: `next build` (default)
5. No environment variables required
6. Add custom domain: `cronica.eggerco.com`

Dynamic `/details` share previews require a Next.js host like Vercel. Clean URLs are enabled in `vercel.json`.

## Universal links

`/.well-known/apple-app-site-association` is served for iOS Universal Links to open `/details` in the app. The app also needs the Associated Domains entitlement (`applinks:cronica.eggerco.com`) in `Shared/Configuration/Cronica.entitlements`.

## Pages

| Path | Description |
|------|-------------|
| `/` | Landing page |
| `/details?id=&img=&title=` | Deep-link handler with dynamic OG previews |
| `/privacy` | Privacy policy |

## Fonts

Uses [Nunito](https://fonts.google.com/specimen/Nunito) (SIL Open Font License) via `next/font/google`. OG images use licensed TTF files in `public/fonts/`.
