import Link from "next/link";

export default function NotFound() {
  return (
    <section data-nav-theme="dark" className="grain hero-glow flex min-h-screen flex-col items-center justify-center px-6 text-center">
      <p className="text-xs font-bold uppercase tracking-[0.2em] text-coral">404</p>
      <h1 className="mt-4 text-4xl font-extrabold tracking-tight">Page not found</h1>
      <p className="mt-4 text-white/50">The page you&apos;re looking for doesn&apos;t exist.</p>
      <Link href="/" className="btn btn-primary mt-10">
        Back to home
      </Link>
    </section>
  );
}
