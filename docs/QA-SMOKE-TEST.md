# Cronica smoke-test checklist

Use before App Store / TestFlight releases.

## iPhone
- [ ] Launch → Welcome (first install) → Continue → Home loads
- [ ] Home: trending/sections appear; pull to refresh; offline shows retry
- [ ] Explore: For You + Discover; filters; scroll loads more without duplicate jumps
- [ ] Search: type a query; scopes only after results; open movie/show/person
- [ ] Watchlist: empty state copy; add from details; filters; swipe actions
- [ ] Custom list: create, edit, delete with confirmation
- [ ] Details: add/remove (confirm when enabled), favorite/pin/archive, seasons/episodes
- [ ] Sheets: filters, episode details, list picker — Done dismisses
- [ ] Settings: Appearance tint applies app-wide; Behavior; Notifications
- [ ] VoiceOver: tabs, search field, watchlist add/remove, Continue on Welcome
- [ ] Dynamic Type: largest accessibility size on Home row + Settings
- [ ] Reduce Motion: Welcome dismiss + overview Show More

## Other platforms
- [ ] iPad: split/toolbar search, sheets
- [ ] Mac: sidebar, sheets Done
- [ ] Watch: empty watchlist, trending load/error, open title
- [ ] tvOS smoke (if shipping)

## Release gates
- [ ] Xcode archive succeeds for shipping targets
- [ ] Version/build numbers match across app + widget
- [ ] SENTRY_DSN / TMDB key present in release config
