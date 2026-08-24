import {
  Bell,
  Bookmark,
  Cloud,
  Compass,
  Glasses,
  Laptop,
  Layers,
  LucideIcon,
  PlayCircle,
  Smartphone,
  Tablet,
  Tv,
  Watch,
} from "lucide-react";

export const features: {
  icon: LucideIcon;
  title: string;
  description: string;
}[] = [
  {
    icon: Bookmark,
    title: "Watchlist",
    description: "Save movies and shows. Organize with lists, favorites, pins, and archives.",
  },
  {
    icon: PlayCircle,
    title: "Episode tracking",
    description: "Mark what you've watched and pick up exactly where you left off.",
  },
  {
    icon: Bell,
    title: "Release reminders",
    description: "Local notifications for new episodes and movie releases in your watchlist.",
  },
  {
    icon: Cloud,
    title: "iCloud sync",
    description: "Core Data and CloudKit keep your list in sync across all your devices.",
  },
  {
    icon: Compass,
    title: "Discover",
    description: "Explore, search, and browse with accurate data from The Movie Database.",
  },
  {
    icon: Layers,
    title: "Everywhere Apple",
    description: "Native apps for iPhone, iPad, Mac, Apple Watch, Apple TV, and Vision Pro.",
  },
];

export const platforms: { name: string; icon: LucideIcon }[] = [
  { name: "iPhone", icon: Smartphone },
  { name: "iPad", icon: Tablet },
  { name: "Mac", icon: Laptop },
  { name: "Apple Watch", icon: Watch },
  { name: "Apple TV", icon: Tv },
  { name: "Vision Pro", icon: Glasses },
];

export const siteConfig = {
  name: "Cronica",
  description:
    "Track what you watch. Never lose your place. A watchlist for movies and TV with release reminders and iCloud sync across Apple devices.",
  url: "https://cronica.eggerco.com",
  appStoreUrl: "https://apps.apple.com/app/cronica/id1614950275",
  githubUrl: "https://github.com/eggerco/cronica",
  supportEmail: "support@eggerco.com",
};
