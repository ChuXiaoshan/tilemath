# Tile Calculator — Design Tokens v0.9 (Material 3 → Flutter `ThemeData`)

Draft against brief §4. Typography family finalizes after the 2a/2b pick; everything else is stable.
Derived from the Broadsheet system ramps (OKLCH-matched steps), re-mapped to M3 roles.

**Seed color:** `#0088B0` (process cyan).

---

## 1. ColorScheme — Light (primary scheme; jobsite daylight is the main scenario)

| Role | Hex | Contrast (vs pairing) | Notes |
|---|---|---|---|
| primary | `#006786` | 5.7:1 on surface (AA); onPrimary on it 5.7:1 (AA) | Filled actions: Done key, selected chips. Darker than seed so **text on fills passes AA**; seed `#0088B0` alone maxes out at 3.7:1 and can't host 4.5:1 text |
| onPrimary | `#F3F2F2` | 5.7:1 on primary ✓ AA | |
| primaryContainer | `#CBEEFF` | — | Active-segment key (`in`), edited-segment highlight |
| onPrimaryContainer | `#004961` | ≈7.8:1 on container ✓ 7:1 | |
| secondary | `#0088B0` | 3.7:1 on surface — **non-text only** (≥3:1 UI) | Focus rings, caret, selection tint, 1.5dp focused-input border. Never body text |
| tertiary | `#AA0B56` | 6.5:1 on surface ✓ AA | **Cutout semantic** (negative areas) — reserved, never decorative |
| tertiaryContainer / onTertiaryContainer | `#FFF1F4` / `#790E3D` | ≈9:1 ✓ | Cutout tag |
| surface | `#F3F2F2` | — | App background ("paper") |
| surfaceContainerLow | `#EAE9E9` | — | Input fills, keyboard tray |
| surfaceContainerHigh | `#D7D3D3` | — | Pressed states, ad-banner placeholder ground |
| surfaceContainerLowest | `#F8F4F4` | — | Raised keycaps |
| onSurface | `#201E1D` | **14.8:1** on surface ✓ 7:1 | All values & numbers |
| onSurfaceVariant | `#605D5D` | 5.8:1 on surface ✓ AA | Labels/captions ≥12sp only; **numbers never use this role** |
| outline | `#949191` | ≥3:1 vs surface | Input/key borders |
| outlineVariant | `#D1D0D0` | — | Hairline only inside components (never section dividers) |
| error | `#B3261E` | ≈5.3:1 on surface ✓ AA | Validation only — small-area hint does **not** use it |

## 2. ColorScheme — Dark (recalibrated, not inverted)

| Role | Hex | Contrast | Notes |
|---|---|---|---|
| primary | `#62C5EE` | **8.5:1** on surface ✓ 7:1 | Text-capable in dark |
| onPrimary | `#0A303E` | 7.1:1 ✓ | |
| primaryContainer / onPrimaryContainer | `#004961` / `#CBEEFF` | ≈7.8:1 ✓ | |
| secondary | `#38A6CF` | ≥3:1 non-text | Focus/caret |
| tertiary | `#FF90B1` | ≈7.8:1 ✓ | Cutout |
| surface | `#201E1D` | — | |
| surfaceContainerLow / High | `#2D2B2B` / `#444141` | — | Tray / keycaps |
| onSurface | `#EAE7E7` | **13.2:1** ✓ 7:1 | |
| onSurfaceVariant | `#BAB6B6` | 8.3:1 ✓ | |
| outline / outlineVariant | `#605D5D` / `#444141` | — | |
| error | `#F2B8B5` | ≈9:1 ✓ | |

## 3. TextTheme (roles actually used)

Family (decided, option 3a): **IBM Plex Sans** — tnum verified by live glyph-width measurement at 66px and 11px; Plex Latin x-height (51.6) seats with Noto Sans SC (51.7) better than Noto Latin (53.6); engineering voice fits the tool.

Script pairing table:

| Script | Family | Notes |
|---|---|---|
| Latin (base) | IBM Plex Sans | Carries **all digits, units, dimension expressions** in every locale, with `FontFeature.tabularFigures()` |
| Arabic | IBM Plex Sans Arabic | Chain Latin-first (`'IBM Plex Sans','IBM Plex Sans Arabic'`) so digits keep Plex Latin metrics; baseline check in RTL sample (4e). If a device ships odd vertical metrics, swap Arabic family only — digits unaffected |
| Devanagari | IBM Plex Sans Devanagari | |
| Thai | IBM Plex Sans Thai | Body/label line heights ≥1.4 already sized for Thai stacks |
| Simplified Chinese | Noto Sans SC | Plex has no CJK; x-height fit measured (51.6/51.7) |

| Role | Size/Line (sp) | Weight | Letter-spacing | Tabular | Use |
|---|---|---|---|---|---|
| displayLarge | 64/64 | 600 | −1.0 | **✓** | Tiles-needed figure (arm's-length) |
| headlineSmall | 23/28 | 600 | 0 | **✓** | Keyboard digits |
| titleLarge | 19/26 | 600–700 | −0.2 | — | App bar title |
| titleMedium | 17/24 | 600 | 0 | **✓** | Result values (area, boxes, cost) |
| bodyLarge | 16/24 | 400 | 0 | **✓** | Field values, fraction keycaps |
| bodyMedium | 14/21 | 400 | 0 | — | Helper copy, hints |
| bodySmall | 12/18 | 400 | 0 | — | Captions, ad label |
| labelLarge | 14/20 | 600 | +0.1 | — | Text buttons (+ Add area), fn keycaps (ft/in/Next/Done) |
| labelMedium | 12/16 | 600 | +1.0, uppercase | — | Section kickers |
| labelSmall | 11/16 | 400 | +0.2 | — | Row labels (Area 1) |

- Tabular figures via `FontFeature.tabularFigures()`; **numbers, units and dimension strings always render in the Latin family with Western digits 0-9, LTR, in every locale** (incl. Arabic/Hindi/Thai/Chinese).
- Line heights ≥1.4× on body/label roles — validated for Thai tall stacks; display roles carry digits only, so 1.0 is safe.
- Imperial rendering uses real prime marks: `12′ 3-1/2″` (U+2032/U+2033), never straight quotes.
- Metric decimal keycap and rendered separators are **locale-variable** (`.` / `,`; Brazil `1.234,56`). Mocks show `.` only.
- Short strings (chips, seg options, keycap labels) are sized for ~2× German expansion; overflow rule: wrap to 2 lines → then ellipsize; keycaps never ellipsize (fall back to symbol).

## 4. Spacing (4dp base)

| Step | Use |
|---|---|
| 4 | Icon↔label gaps, keycap internal padding |
| 8 | Key gutters, chip gaps, stacked result rows |
| 12 | Area-row gaps, input horizontal padding |
| 16 | Screen margins, keyboard tray padding |
| 24 | Between form sections (whitespace IS the divider) |
| 32 | Above results block; two-pane column gutter (3.3) |
| 48 | Min touch target; tablet key size sits at 56 |

## 5. Radius

| Step | Use |
|---|---|
| 1dp | Mini tiling preview tiles |
| 2dp | Inputs, keycaps, chips, tags, segmented options |
| 4dp | Result panel, dialogs, banner placeholder |
| Never | Pills/full-round — everything reads as cut tile, not capsule |

## 6. Other hard rules

- **Touch:** ≥48×48dp everywhere (visual glyph may be smaller; hit slop expands — e.g. row-delete 44 visual / 48 hit). Tablet keyboard keys 56dp.
- **Dividers:** section structure by whitespace + surface-color steps only; 1dp `outline` borders live on inputs/keys. The keyboard↔banner gap is a 16–18dp non-interactive band: spacing + surface change + tape-measure tick texture (AdMob-compliant, looks intentional).
- **Motion:** keyboard in 240ms `cubic-bezier(0.05,0.7,0.1,1)` / out 180ms `cubic-bezier(0.3,0,0.8,0.15)`; result value change = instant swap with 90ms opacity settle (no count-up — trust); row add 200ms / remove 160ms `cubic-bezier(0.2,0,0,1)` height+fade. All collapse to simple fades under reduced-motion.
- **RTL:** layout mirrors; **numeric keypad order, digits, and dimension expressions never mirror**; direction-neutral icons (gear) don't flip.
