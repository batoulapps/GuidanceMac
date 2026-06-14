<div align="center">

# Guidance · هداية

### Prayer times, beautifully at home in your menu bar.

Guidance is a calm, native macOS companion for the five daily prayers. It lives in your menu bar, brings a living prayer schedule to Desktop and Notification Center widgets, and sounds the adhan exactly when it should - accurate, private, and quietly elegant.

![macOS 14+](https://img.shields.io/badge/macOS-14.0%2B-000000?logo=apple&logoColor=white) ![Swift 6](https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&logoColor=white) ![SwiftUI](https://img.shields.io/badge/Built%20with-SwiftUI-0A84FF?logo=swift&logoColor=white) ![Languages](https://img.shields.io/badge/languages-9-2EA043) ![Version](https://img.shields.io/badge/version-3.0-2EA043) ![Privacy](https://img.shields.io/badge/tracking-none-2EA043)

<br>

<a href="https://apps.apple.com/eg/app/guidance/id412759995">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/badges/mac-app-store-en-white.svg">
    <img alt="Download Guidance on the Mac App Store" src="docs/badges/mac-app-store-en-black.svg" height="48">
  </picture>
</a>
&nbsp;&nbsp;
<a href="https://apps.apple.com/eg/app/guidance/id412759995">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/badges/mac-app-store-ar-white.svg">
    <img alt="حمّل هداية من ماك آب ستور" src="docs/badges/mac-app-store-ar-black.svg" height="48">
  </picture>
</a>

</div>

---

## Why Guidance

- **A living menu bar.** More than a clock - the status item shifts color as a prayer approaches, counts down to the minute, then counts up after the adhan, and badges itself when something needs your attention.
- **Widgets that breathe.** Small, medium, and large widgets render the same refined "living schedule" as the app, with the next prayer expanding in place, a Hijri date, your location, reminders, and one-tap adhan control.
- **Adhan, your way.** Per-prayer sounds, pre- and post-prayer reminders, a Friday Jumu'ah override, custom audio, and a global silent mode - all with a graceful catch-up after sleep or launch.
- **Genuinely yours.** Five hand-tuned themes plus a guard-railed custom theme, nine languages with full right-to-left support, and localized digits throughout.
- **Private by design.** Prayer times are computed on your Mac. Your location never leaves it. No analytics, no tracking, no accounts.

<div align="center">

<!--
  Drop product shots into a docs/ folder to bring this section to life.
  Suggested captures: menu-bar dropdown, the three widget sizes, the Appearance tab.
-->

| Menu bar | Widgets | Settings |
| :---: | :---: | :---: |
| _add `docs/menu-bar.png`_ | _add `docs/widgets.png`_ | _add `docs/settings.png`_ |

</div>

---

## Features

### The menu bar

The heart of Guidance. A click opens a themed "living schedule": a Hijri-dated header, the day's six prayers in a vertical list, and the next prayer expanded inline into a hero card with a live countdown.

- **Status item, at a glance.** Choose what shows in the menu bar: the moon-and-stars icon, the next prayer's name (full or abbreviated), and either a countdown or the prayer's clock time - in any combination.
- **State you can read in a color.** The label turns **red** in the final 15 minutes before a prayer, **green** for a 15-minute Iqama count-up after the adhan, and takes on the **active audio** color while a sound is playing. A subtle badge appears if location needs attention.
- **Interactive, not just informative.** Toggle any prayer's alert, flip global silent mode, and stop a playing adhan right from the dropdown.
- **To the second when it matters.** The countdown ticks per-second only in the last minute, and stays calm and minute-resolution the rest of the time.

### Widgets

Native WidgetKit widgets for the Desktop and Notification Center, in **small, medium, and large** sizes - all driven by the same design system as the menu bar, so the two never drift.

- The **next prayer** with a live countdown, today's full schedule, the **Hijri date**, your location, and per-prayer reminder details.
- Reflects **silent mode**, the **imminent** state, the post-prayer count-up, and any **active adhan**.
- **Tap to stop** audio directly from the widget, or tap to open the app.
- An honest empty state: before the app has ever run, the widget invites setup instead of showing stale or fake times.

### Notifications & adhan

A notification and audio engine built for real life.

- **Per-prayer configuration.** Each prayer has its own main alert, an optional **pre-prayer reminder** and **post-prayer reminder**, with independent sounds and offsets from 1 to 120 minutes.
- **Jumu'ah override.** Give Friday's Dhuhr its own notification and sound settings, applied automatically on Fridays.
- **Sounds.** Six built-in adhans - **Mishary Alafasy, Fajr Adhan, Makkah, Istanbul, Yusuf Islam, and Al-Aqsa** - plus your own **custom audio file**, the system sound, or silence. Per-prayer volume and an optional **du'ā'** after the adhan.
- **Considerate playback.** Guidance pauses Music or iTunes while the adhan plays, then steps out of the way. A global **silent mode** mutes everything in one switch.
- **Stop from anywhere.** End a playing adhan from the menu bar, the notification, or the widget.
- **Never misses, never double-fires.** After sleep, a clock change, or a cold launch, Guidance catches up on a missed alert within a sensible grace window instead of staying silent or replaying old ones.

### Appearance & themes

Guidance ships with five calm, hand-built widget themes:

| Theme | Mood |
| --- | --- |
| **Nocturne** | Midnight blue with a brass guiding light (the default) |
| **Dawn** | Warm sand and soft teal, a light-first palette |
| **Oasis** | Deep midnight with emerald and teal |
| **Ink** | Near-monochrome graphite with a brass whisper |
| **High Contrast** | Color-blind-safe yellow and blue on near-black or white |

Prefer your own look? The **custom theme** lets you pick an accent and primary color over a curated background base (Midnight, Sand, or Graphite) and pin the appearance to System, Always Dark, or Always Light. A **live preview** renders the real widget as you tweak, and built-in **contrast and hue guardrails** keep your countdown readable and your colors distinct from the functional reds and greens.

### Calculation & accuracy

Prayer times are computed locally with the open-source [Adhan](https://github.com/batoulapps/Adhan) library.

- **Eleven calculation methods** plus Custom: Egyptian, Karachi, North America, Muslim World League, Umm al-Qura, Gulf, Moonsighting Committee, Kuwait, Qatar, Singapore, and Tehran. Custom lets you set your own Fajr and Isha twilight angles.
- **Auto-detection.** Guidance can pick a sensible method from your country and choose a high-latitude rule based on your latitude - or you can set both by hand.
- **Madhab.** Shafi or Hanafi for the Asr calculation.
- **High-latitude rules.** Middle of the Night, Seventh of the Night, or Twilight Angle, with a graceful fallback at extreme latitudes.
- **Fine tuning.** Per-prayer minute adjustments, a Hijri date offset (±3 days), and an optional delayed Isha during Ramadan.

### Location

- **Automatic or manual.** Use Core Location for an automatic, reverse-geocoded city, or search for any place by name.
- **Time zone control.** Pick a time zone manually when you want prayer times for a place other than where you are.
- **Resilient offline.** Prayer times never need the network - they come from stored coordinates. If a city label can't be resolved while you're offline, Guidance quietly re-resolves it the moment you reconnect.

### Languages & localization

Nine fully localized languages: **English, Arabic, French, Urdu, Indonesian, Turkish, Persian, Bengali, and Malay.**

- **Switch in-app**, with the entire interface - including the Settings window title - updating live.
- **Right-to-left** layouts for Arabic, Urdu, and Persian.
- **Localized digits** (Arabic-Indic, Persian, Bengali) across every countdown, clock, and widget.

---

## Requirements

- **macOS 14.0 (Sonoma)** or later
- An Apple Silicon or Intel Mac

## Getting started

Guidance is a Batoul Apps product, available on the
**[Mac App Store](https://apps.apple.com/eg/app/guidance/id412759995)**. Learn more
and find help at **[batoulapps.com/software/guidance](https://batoulapps.com/software/guidance/)**.

Launch it once and grant location and notification permission, and the menu bar, widgets, and adhan are ready - no account, no setup wizard.

---

## Privacy

Guidance is built to keep your worship private.

- **Your location stays on your Mac.** It is used only to compute prayer times and to label your city. It is never uploaded or shared.
- **Prayer times are computed locally** and work fully offline. The network is touched only to translate coordinates into a city name and for manual location search.
- **No tracking, no analytics, no data collection.** Guidance declares no collected data types and no tracking.
- **Fully sandboxed.** The app runs in the macOS App Sandbox, and custom adhan files are accessed through scoped, read-only bookmarks you explicitly grant.

---

## Credits

- **Development** - [Batoul Apps](https://batoulapps.com/)
- **Design** - [@Bandar](https://twitter.com/bandar)
- **Prayer time calculation** - [Adhan](https://github.com/batoulapps/Adhan)
- With special thanks to Hamza & Yasir.

<div align="center">

_Guidance 3.0 - a complete, modern SwiftUI rebuild for macOS._

</div>
