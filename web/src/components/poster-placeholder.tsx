import { Film } from "lucide-react";

type PosterPlaceholderProps = {
  className?: string;
};

export function PosterPlaceholder({ className }: PosterPlaceholderProps) {
  return (
    <div
      className={`flex size-full flex-col items-center justify-center bg-gradient-to-b from-white/10 to-white/5 ${className ?? ""}`}
      aria-hidden
    >
      <div className="flex size-16 items-center justify-center rounded-2xl bg-white/10 ring-1 ring-white/10">
        <Film className="size-8 text-white/30" strokeWidth={1.5} />
      </div>
    </div>
  );
}
