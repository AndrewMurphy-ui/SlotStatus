# SlotStatus

<p align="center">
  <img src="https://img.shields.io/badge/Interface-20505-blue" alt="Interface">
  <img src="https://img.shields.io/badge/WoW-Burning%20Crusade%20Classic-orange" alt="WoW">
  <img src="https://img.shields.io/badge/Version-1.0.1-brightgreen" alt="Version">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green" alt="License"></a>
  <img src="https://img.shields.io/badge/CurseForge-SlotStatus-f16436" alt="CurseForge">
</p>

<p align="center">
  <i>A lightweight but complete gear-maintenance addon for <b>World of Warcraft: Burning Crusade Classic (Anniversary)</b>.</i>
</p>

<p align="center">
  <img src="images/durability-bars-character-frame.png" alt="Durability bars on the Character Frame" width="500">
  <br>
  <sub><i>Color-coded durability bars update live on every equipment slot</i></sub>
</p>

SlotStatus started as a simple idea — show durability bars directly on the Character Frame so you don't have to hover every slot to check your gear — and grew into a full suite for tracking, repairing, and maintaining your equipment without ever leaving the game.

Everything is **per-character**, stored locally, and works **out of the box**. No libraries, no dependencies, no setup required.

---

## Table of Contents

- [Features](#features)
  - [Durability Bars on the Character Frame](#durability-bars-on-the-character-frame)
  - [Rich Tooltips](#rich-tooltips)
  - [World Map Vendor Pins](#world-map-vendor-pins)
  - [Vendor Auto-Discovery](#vendor-auto-discovery)
  - [Automation at the Merchant](#automation-at-the-merchant)
  - [Warning System](#warning-system)
  - [Gear Overview Window](#gear-overview-window)
  - [Alert Column](#alert-column)
  - [Minimap Button & Broker Support](#minimap-button--broker-support)
  - [Full Options Panel](#full-options-panel)
- [Slash Commands](#slash-commands)
- [First-Run Welcome](#first-run-welcome)
- [Design Philosophy](#design-philosophy)
- [Installation](#installation)
- [Compatibility](#compatibility)
- [Changelog](#changelog)
- [Feedback & Issues](#feedback--issues)
- [License](#license)

---

## Features

### Durability Bars on the Character Frame

Slim, color-coded bars sit flush against every equipment slot on the paperdoll. A single glance tells you which pieces are fine, which are worn, and which are about to break.

- **Healthy**, **Worn**, and **Critical** color tiers
- Special tints for **Accessory** and **Utility** slots
- Live updates when durability changes, gear swaps, or repairs happen
- Fully customizable colors, thresholds, alpha, thickness, and position

### Rich Tooltips

<p align="center">
  <img src="images/tooltip-damaged-overview.png" alt="Rich item tooltip showing repair cost and nearest vendor" width="420">
  <br>
  <sub><i>Hover any equipped item to see repair cost and the nearest repair vendor</i></sub>
</p>

Hover any equipped item to see:

- **Item Level**
- **Slot Repair** — estimated cost to repair just that one piece
- **Total Repair Cost** — all slots combined
- **Nearest Repair Vendor** — name, subzone, zone, and coordinates
- A green **Repair here** callout when you're standing on one

### World Map Vendor Pins

Anvil icons appear on the world map marking every known repair vendor in the zone you're viewing. Pins refresh automatically as you open and resize the map.

### Vendor Auto-Discovery

SlotStatus ships with a built-in repair-vendor database and also **learns new vendors on its own**. The first time you open any merchant that can repair, SlotStatus records their name, zone, subzone, and exact coordinates. Over time you build a personal atlas of every repair vendor you've met.

> View the full list at any time with `/ss vendors`.

---

### Automation at the Merchant

Open any repair vendor and SlotStatus handles the boring parts for you — all toggleable:

- **Auto-Repair** — repairs everything the moment the merchant window opens
- **Guild Bank First** — if you have the withdraw cap, pulls repair costs from guild funds before touching your own gold
- **Auto-Sell Grays** — clears Poor-quality junk from your bags and reports the gold earned

Every transaction is tracked in the **Stats** tab so you know exactly how much you've spent and earned.

### Warning System

Three levels of heads-up so you never get caught with broken gear:

- **Low-Durability Warnings** — off, chat-only, or chat + on-screen flash + sound
- **Pre-Combat Warning** — fires the moment you enter combat with any slot below a configurable threshold
- **Animated Bar Pulse** highlights the exact slot that's in trouble

> Default thresholds: **25%** for the standard warning and **35%** for the pre-combat check — both adjustable.

---

### Gear Overview Window

<p align="center">
  <img src="images/gear-overview.png" alt="Gear Overview window — clean state" width="500">
  <br>
  <sub><i>At-a-glance gear condition, repair cost, and per-slot durability</i></sub>
</p>

A custom-styled dialog you can open from the minimap button, a broker panel (Titan / Bazooka / ElvUI), or a slash command. It shows:

- **Condition** verdict — at-a-glance summary of your overall gear state (Excellent, Needs repair, Worn, or Critical)
- **Repair Cost** block — total repair due vs gold on hand, with an **OK** or **short X** indicator
- **Gear Wear** stat sheet — slots needing repair, your lowest-durability piece, a Critical / Worn / OK status breakdown, and average durability
- **Slot Table** — every equipment slot with its current durability, color-coded to match the bars on your paperdoll
- **Repair All** and **Find Nearest Vendor** footer buttons — one click to repair on the spot, or route to the closest known vendor

### Alert Column

<p align="center">
  <img src="images/gear-repair-overview-damaged.png" alt="Gear Overview with Alert chips on damaged gear" width="500">
  <br>
  <sub><i>The Alert column flags every slot below 100% — Minor, Worn, or Critical</i></sub>
</p>

The rightmost **Alert** column gives you a per-row at-a-glance marker for any slot below 100% durability. Three tiers:

| Chip       | Meaning                                                                | Default trigger |
| ---------- | ---------------------------------------------------------------------- | --------------- |
| `!! Crit`  | Dangerously low — risks breaking mid-fight                             | `< 40%`         |
| `! Worn`   | Below the warning threshold — repair at the next vendor                | `< 75%`         |
| `· Minor`  | Not urgent, but no longer pristine                                     | `< 100%`        |
| *(blank)*  | Slot is at 100% durability                                             | `== 100%`       |

Chip color and text tint track your Healthy/Worn/Critical color pickers, so if you recolor your durability bars on the **Advanced** tab, the chips follow automatically.

### Minimap Button & Broker Support

- Draggable minimap button, position remembered per character
- **Left-click** — opens the Gear Overview window
- **Right-click** — opens the options panel
- Exposes a **LibDataBroker-1.1** data source so Titan Panel, Bazooka, ElvUI DataBars, and other display addons can show your average durability on their bar
- **No dependency** — if no broker addon is loaded, SlotStatus silently does nothing and moves on

---

### Full Options Panel

<p align="center">
  <img src="images/menu-preview.png" alt="SlotStatus options menu" width="550">
  <br>
  <sub><i>Live preview, color pickers, and threshold sliders on the Advanced tab</i></sub>
</p>

Accessible from **Interface Options** or `/ss options`. Four tabs:

| Tab          | Contents                                                                                                                                                |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **General**  | Display toggles, all three merchant automations, debug prints                                                                                           |
| **Warnings** | Warning mode, sound and flash, pre-combat warning, threshold sliders                                                                                    |
| **Advanced** | Five color pickers (Healthy, Worn, Critical, Accessory, Utility), live bar preview, G→Y and Y→R threshold sliders, bar alpha, thickness, offset sliders |
| **Stats**    | Session and lifetime gold in/out, with a **Reset** button                                                                                               |

> Every setting is saved **per character**.

---

## Slash Commands

| Command                          | What it does                     |
| -------------------------------- | -------------------------------- |
| `/ss` or `/slotstatus`           | Show help                        |
| `/ss options`                    | Open the options panel           |
| `/ss advanced`                   | Panel → Advanced tab             |
| `/ss stats`                      | Session gold in/out              |
| `/ss reset`                      | Reset session stats              |
| `/ss autorepair`                 | Toggle auto-repair               |
| `/ss autosell`                   | Toggle auto-sell grays           |
| `/ss guild`                      | Toggle "guild bank first"        |
| `/ss warn [N\|off\|chat\|full]`  | Warning mode and threshold       |
| `/ss pins`                       | Toggle map pins                  |
| `/ss mm`                         | Toggle minimap button            |
| `/ss vendors [clear]`            | List or clear discovered vendors |
| `/ss discover`                   | Toggle vendor auto-discovery     |
| `/ss welcome`                    | Re-open the welcome popup        |
| `/ss debug`                      | Toggle debug prints              |

---

## First-Run Welcome

New characters see a one-time welcome popup two seconds after login that explains how to open the addon and lists the main features. It appears **once per character**, then never again — re-openable anytime with `/ss welcome`.

---

## Design Philosophy

SlotStatus is designed to **stay out of your way**. It doesn't modify the Blizzard UI, doesn't add third-party frames you didn't ask for, and doesn't nag. It sits quietly on the Character Frame showing you what you need to know, and steps in only at the merchant window to save you a few clicks.

- No library dependencies
- No taint on the default UI
- Per-character saved variables
- Lightweight — minimal CPU and memory footprint

---

## Installation

### Option 1 — CurseForge (recommended)

Install via the [CurseForge app](https://www.curseforge.com/wow/addons) and search for **SlotStatus**. Updates deliver automatically.

### Option 2 — Manual install

1. Download the latest release ZIP from the [Releases page](../../releases) (or the [CurseForge Files tab](https://www.curseforge.com/wow/addons)).
2. Extract the archive. You should get a folder named `SlotStatus/` containing `SlotStatus.toc`, `SlotStatus.lua`, and `logo.tga`.
3. Drop that `SlotStatus/` folder into your WoW AddOns directory:

   | Client flavor                   | Path                                                                              |
   | ------------------------------- | --------------------------------------------------------------------------------- |
   | **Burning Crusade / Anniversary** | `World of Warcraft\_anniversary_\Interface\AddOns\`                             |
   | **Classic Era**                 | `World of Warcraft\_classic_era_\Interface\AddOns\`                               |
   | **Classic (WotLK / Cata / MoP)** | `World of Warcraft\_classic_\Interface\AddOns\`                                  |

4. Restart WoW (a `/reload` is not enough for first install — the client needs to scan the TOC).
5. At the character-select screen, click **AddOns** (bottom-left) and make sure **SlotStatus** is enabled.
   - If the client flags it as "out of date," tick **Load out of date AddOns** at the top of the list. The addon declares `Interface: 20505` (TBC Classic 2.5.5) for widest compatibility; it runs cleanly on Anniversary/Classic Era with that checkbox on.
6. Log in and type `/ss` to confirm it loaded.

### Uninstall

Delete the `SlotStatus/` folder from your AddOns directory. Saved settings live in `WTF\Account\<account>\<realm>\<character>\SavedVariables\SlotStatus.lua` — remove that file too if you want a clean slate.

---

## Compatibility

- **Game versions:** designed for Burning Crusade Classic / Classic Anniversary (TOC `Interface: 20505`). Also loads cleanly on Classic Era with **Load out of date AddOns** enabled.
- **Other addons:** does **not** replace or reparent any Blizzard frame, so it coexists with ElvUI, Bartender, Titan Panel, Bazooka, etc. without taint.
- **Libraries:** none required. LibDataBroker-1.1 is *optional* — if a broker display addon is loaded, SlotStatus publishes a data source; if not, nothing happens.
- **Localization:** English strings only at the moment. Locale-agnostic for all gameplay logic (uses slot IDs, not item names).

---

## Changelog

### v1.0.1 — Apr 23, 2026

- **Fixed:** The Gear Overview **Alert** column now shows a subtle `· Minor` chip on every row below 100% durability. Previously the column stayed blank when all damaged items were still in the Healthy band, even though the **Condition** header said *"Needs repair"* — which looked like a broken column.
- **Internal:** The three on-screen version strings (Gear Overview footer, options panel header
