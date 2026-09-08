# Luminance research and calibration

Research date: 2026-09-07. Exa was used for ergonomic and manufacturer sources;
Firecrawl's developer index was used for BetterDisplay control behavior. The
maintainer's evening environment is a dim room with a desk lamp or indirect light.

## What the evidence supports

Brightness should follow the actual lighting around the screens, with manual
control retained. The University of Toronto's occupational lighting guide
recommends matching the display to room brightness and controlling glare; it
also explains that lighting needs depend on the task and the individual.
[University of Toronto lighting guide](https://ehs.utoronto.ca/wp-content/uploads/2023/07/Lighting-Ergonomics-Guideline-2023-Final.pdf).

EIZO suggests about **100–150 cd/m²** for an office at **300–500 lux**, with lower
screen luminance appropriate for dimmer home environments. This is manufacturer
guidance, not a personalized clinical threshold. Its practical non-meter method
is to compare an on-screen white page with white paper under the room lighting.
[EIZO guidance](https://www.eizo.com/library/basics/10_ways_to_address_eye_fatigue/),
[EIZO office settings](https://www.eizo.ee/library/basics/more-ways-to-save/).

The 16-inch 2023 MacBook Pro is specified for **500 nits SDR**, with **1000 nits
sustained / 1600 peak for HDR**. The Dell U2718Q is specified for **350 cd/m²
typical**. These are capabilities, not recommended sustained office settings.
Apple explicitly supports its XDR preset for general use; the preset's name alone
is not a reason to remove it. Deliberate extra-brightness upscaling is a separate
choice. [Apple specifications](https://support.apple.com/en-us/111838),
[Apple presets](https://support.apple.com/en-us/108321),
[Dell specifications](https://i.dell.com/sites/csdocuments/Product_Docs/en/dell_ultrasharp_27_4k_monitor_u2718q_product_spec_sheet.pdf).

BetterDisplay distinguishes hardware, software, and combined brightness. The
combined percentage depends on the control method, so a percentage is not a
photometric reading. Our raw external VCP writes also do not establish physical
readback. [BetterDisplay CLI reference](https://github.com/waydabber/BetterDisplay/wiki/Integration-features,-CLI).

## Proposed starting targets

These ranges are **our provisional calibration suggestions** for this workflow,
extrapolating downward from normal-office guidance for a dim, indirectly lit room.
They are not measured values, a universal schedule, or research-established
optimal values for this person. One nit equals one cd/m²; room lux is a different
quantity. Adjust by the actual room conditions, not merely the preset's name.

| Preset / conditions | Starting screen-white target |
| --- | --- |
| Dawn / low early light | 80–100 nits |
| Day / normal office light | 120–150 nits |
| Afternoon / moderate room light | 100–120 nits |
| Evening / dim room with lamp | 80–100 nits |
| Night / dim indirect lighting | 50–80 nits |

For a brighter-than-usual day, first reduce glare or adjust blinds; increase
brightness only as needed for readable content. Meeting, Read, and Stream do not
inherently need higher luminance than the current room. HDR/video evaluation is
a separate content-specific task; these targets describe ordinary SDR work.

The old 105–150% software targets are inherited preferences, not evidence-based
comfort settings. We preserve them as factory fallbacks while adding calibration;
we do not silently replace them with guessed percentages or claim that 30% of a
500-nit maximum necessarily produces 150 nits.

## Calibrate without inventing a percentage-to-nits conversion

1. Set the room lighting as you normally use it for the target period. Keep
   ambient light and screen position consistent while comparing.
2. Use an ordinary SDR white page on both screens and white paper lit by the desk
   lamp. Adjust until the screens feel comparable to the paper, with text clearly
   readable. This is a visual starting point, **not a measurement in nits**.
3. Use `bd-backlight <percent>` for the built-in hardware level. This sets software
   brightness to 100%, avoiding software upscaling during ordinary calibration.
   Use `bd-set port <percent>` for the external display. Start near your current
   comfortable level and adjust gradually; there is no universal percentage pair.
4. Once the managed settings are comfortable, use `bd-save night` (or the relevant
   preset). This saves outside Git in `~/.config/dotfiles/display-profiles.json`,
   including separate built-in hardware/software and external values.
5. Repeat under daytime and evening lighting. `bd-auto` uses your saved overrides;
   any manual adjustment takes control again until you select Auto explicitly.

If a display colorimeter is available, measure a consistent SDR white patch on
each display to map the chosen nits to command percentages. A phone lux app or the
Mac ambient sensor measures a different quantity and is not a substitute for this
screen measurement. Do not change gamma/contrast solely to chase matching nits.

No physical luminance measurements or participant comfort tests were performed
by this research. The controller work provides repeatable saved controls; final
personal calibration requires observation at the desk.
