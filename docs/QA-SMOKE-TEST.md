# Cronica smoke-test checklist

Use before App Store / TestFlight releases. Code for the items below is in place — this checklist verifies them on device.

## iPhone
- [ ] Launch → Welcome (first install) → Continue → Home loads
- [ ] Welcome with Reduce Motion on (no animation stutter)
- [ ] Home: trending/sections appear; pull to refresh; offline shows retry
- [ ] Explore: For You + Discover; filters; scroll loads more without duplicate jumps; offline alert Retry
- [ ] Search: type a query; scopes only after results; failure shows Retry; open movie/show/person
- [ ] Search context Remove asks for confirmation when setting is on
- [ ] Watchlist: empty state copy; add from details; filters; swipe/context Remove confirms when setting is on
- [ ] Custom list: create, edit, delete with confirmation
- [ ] Details: add/remove (confirm when enabled), favorite/pin/archive, seasons/episodes
- [ ] Sheets: filters, episode details, list picker — Done dismisses
- [ ] Settings: Appearance tint applies app-wide; Behavior Clear Cache confirms; Notifications
- [ ] VoiceOver: tabs, search field, watchlist add/remove, Continue on Welcome
- [ ] Dynamic Type: largest accessibility size on Home row + Settings
- [ ] Reduce Motion: Welcome dismiss + overview Show More

## Other platforms
- [ ] iPad: split/toolbar search, sheets
- [ ] Mac: sidebar, sheets Done, list delete confirmation
- [ ] Watch: empty watchlist, trending load/error + Retry, open title
- [ ] tvOS smoke (if shipping)

## Release gates
- [ ] Xcode archive succeeds for shipping targets
- [ ] Version/build numbers match across app + widget
- [ ] SENTRY_DSN / TMDB key present in release config
