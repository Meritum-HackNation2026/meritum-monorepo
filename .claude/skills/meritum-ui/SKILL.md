---
name: meritum-ui
description: Use before building, changing or reviewing anything visual in Meritum - the web app, moderator panel, evaluation page, extension popup and injected widget, platform and Discord mocks, slides, film frames and marketing graphics. Makes the Meritum design system mandatory (tokens, typefaces, components, verdict colours, copy) and defines the single allowed exception, per-platform skins.
---

# Meritum UI: the design system is mandatory

Every visual surface uses the Meritum design system. Nothing visual is invented: no colour,
font, radius, shadow, icon style or user-facing sentence that is not in the design system.

In `meritum-marketing` and `meritum-design-system` four design skills (frontend-design,
impeccable, design-taste-frontend, emil-design-eng) also apply; their `AGENTS.md` sets the
precedence: the user's instructions, then this design system, then the skills.

## Read before building

From the `meritum-design-system` repo (`design-system/` in the monorepo):

| File | Use it for |
|---|---|
| `DESIGN_SYSTEM.md` | the rules: colours (section 3), typography (4), spacing and shapes (5), components (6), widget on platforms (7), tone (8), motion (9), accessibility (10), slides (11) |
| `tokens/meritum.css` | CSS tokens and the Tailwind v4 `@theme`, light and dark, `[data-host]` platform skins |
| `components/meritum/` | React components (`MeritumMark`, `AnalysisSteps`, `ContextCard`, ...) and their README |
| `copy/pl.json` | every user-facing text; keys match contract codes |
| `contracts/` (`meritum.ts`, `meritum.schema.json`) | data shapes; never hand-write types for API data |
| `extension/widget.css`, `extension/popup/` | Shadow DOM styles and skins for the extension |
| `brand/` | the mark and logotype; never redraw them |

Components in `components/meritum/` that DESIGN_SYSTEM.md section 6.7 lists as out of scope
(`ScamWarningCard`, `CampaignRotation`, `BotDefenseTelemetry`, `QuickReportPopover`) are not used.

## Rules

1. **Tokens only.** Colours, radii, spacing and shadows come from `tokens/meritum.css`
   (`var(--verified)`, Tailwind classes mapped by `@theme`). No hex values or arbitrary
   Tailwind values (`bg-[#…]`, `rounded-[7px]`) in app code.
2. **Typefaces.** Archivo for all interface text; Azeret Mono only for data (IDs, domains in
   tables, dates, times, metric numbers), never for labels or headings. Nothing below 12 px.
3. **Components first.** Use a `components/meritum/` component or a shadcn/ui component styled
   by the tokens before writing a new one. A new reusable component follows DESIGN_SYSTEM.md
   section 6 and is proposed back to the design-system repo.
4. **Verdicts and states.** The five verdicts use their tokens, words and hints from
   `copy/pl.json`; red only for „Fałszywe”. Non-verdict states (doprecyzuj pytanie, poza
   zakresem, problem techniczny) are neutral and never look like a verdict badge. Strength is
   ink-coloured with three level bars.
5. **Never colour alone.** Every state also has a word or a sign.
6. **Copy from `copy/pl.json`.** Never invent or paraphrase user-facing text in code. A missing
   string is added to `copy/pl.json` in the design-system repo first (tone: section 8).
7. **Accessibility: WCAG 2.2 AA in light and dark.** Contrast ≥ 4.5:1, keyboard operable, 2 px
   accent focus ring, Esc closes popups and returns focus, results announced via `aria-live`,
   works from 320 px wide, long Polish labels do not break layout, `prefers-reduced-motion`
   respected.
8. **Motion** per section 9: only in response to the user or to changed data,
   `cubic-bezier(0.16, 1, 0.3, 1)`, 150-550 ms, no loops except the in-progress spinner.
9. **Forbidden** (section 3, 5, 12): gradients, purple, neon, green-on-black, glass/blur,
   coloured side stripes on cards, icon-tile grids, uppercase eyebrow labels, invented sources,
   quotes or results, numbers without „dane symulowane” or reproducible data.

## The one exception: platform skins

The injected extension widget and the platform mocks (X, Facebook, Instagram, Reddit, TikTok,
and the Discord mock) may adapt to the host through the per-platform skins of
DESIGN_SYSTEM.md section 7 (`[data-host]` in `tokens/meritum.css`, `:host([data-host=…])` in
`extension/widget.css`): host font and size, card radius, surfaces and border, button shape,
link colour. These stay Meritum's everywhere: the mark and the word „Meritum” in the header,
verdict words and colours, the sources block with the quote, the AI notice. Never put a
platform logo in the widget or imitate the platform's own content.

Any other deviation from the design system needs a stated reason in the PR description
(section "Design system deviations") and is checked by the reviewer.

## Review checklist (reviewers apply it to every PR that touches UI)

- [ ] DESIGN_SYSTEM.md and the relevant tokens/components were followed; no hard-coded colours, fonts or radii
- [ ] all user-facing text comes from `copy/pl.json`
- [ ] verdicts and states use the right tokens and words; non-verdict states look neutral; nothing by colour alone
- [ ] WCAG 2.2 AA checked in light and dark (contrast, keyboard, focus, screen reader, 320 px)
- [ ] platform skin changes stay within section 7; any other deviation is justified in the PR
- [ ] screenshots in light and dark (and the host skin, for widget or mocks) attached to the PR

Enforcement: reviewers (meritum-pr-review-loop); suggested automated checks in the TS repos are
a `tests/architecture/design-tokens.test.ts` that rejects hex colours and arbitrary Tailwind
values outside `tokens/` (run by `node --test`) and an axe check per page in unit tests
(not a browser e2e job in CI).
