# Cronica Website

Marketing site and universal link handler for [Cronica](https://apps.apple.com/app/cronica/id1614950275).

Part of the [eggerco/cronica](https://github.com/eggerco/cronica) monorepo. Static site served by a **Cloudflare Worker**.

**Live:** [cronica.eggerco.com](https://cronica.eggerco.com)

## Development

From this directory (`web/`):

```bash
npm install
npm run dev
```

Open the local URL shown by Wrangler (usually `http://localhost:8787`).

## Deploy (Cloudflare Workers)

1. Install dependencies: `npm install`
2. Log in to Cloudflare: `npx wrangler login`
3. Deploy: `npm run deploy`
4. In the Cloudflare dashboard, attach the custom domain `cronica.eggerco.com` to this Worker

Static files live in `public/`. The Worker adds dynamic HTML for `/details` share links (including Open Graph metadata).

## Universal links

`/.well-known/apple-app-site-association` is served for iOS Universal Links to open `/details` in the app. The app also needs the Associated Domains entitlement (`applinks:cronica.eggerco.com`) in `Shared/Configuration/Cronica.entitlements`.

## Pages

| Path | Description |
|------|-------------|
| `/` | Landing page |
| `/privacy/` | Privacy policy |
| `/details?id=&img=&title=` | Deep-link handler for shared titles |

## Assets

- `public/assets/opengraph-image.png` — default social preview image
- Replace `public/assets/phone-mockup.png` with a Cronica app screenshot when you have updated marketing artwork.
