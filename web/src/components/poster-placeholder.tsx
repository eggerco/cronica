import { Film } from "lucide-react";

import { cn } from "@/lib/utils";

type PosterPlaceholderProps = {
  className?: string;
};

export function PosterPlaceholder({ className }: PosterPlaceholderProps) {
  return (
    <div
      className={cn(
        "flex size-full flex-col items-center justify-center bg-gradient-to-b from-muted/80 to-muted/40",
        className,
      )}
      aria-hidden
    >
      <div className="flex size-16 items-center justify-center rounded-2xl bg-background/60 ring-1 ring-border/60">
        <Film className="size-8 text-muted-foreground/50" strokeWidth={1.5} />
      </div>
    </div>
  );
}
