import { siteConfig } from "@/lib/content";

export function JsonLd() {
  const schema = {
    "@context": "https://schema.org",
    "@type": "SoftwareApplication",
    name: siteConfig.name,
    operatingSystem: "iOS, iPadOS, macOS, watchOS, tvOS, visionOS",
    applicationCategory: "EntertainmentApplication",
    offers: { "@type": "Offer", price: "0", priceCurrency: "USD" },
    description: siteConfig.description,
    url: siteConfig.url,
    downloadUrl: siteConfig.appStoreUrl,
    author: { "@type": "Organization", name: "Egger, Inc." },
  };

  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(schema) }}
    />
  );
}
