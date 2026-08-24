import { SiteFooter } from "@/components/site-footer";

export default function PrivacyLayout({ children }: { children: React.ReactNode }) {
  return (
    <>
      <main>{children}</main>
      <SiteFooter />
    </>
  );
}
