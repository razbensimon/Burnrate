# Status bar main number — design

**Date:** 2026-10-18
**Status:** Approved
**Product:** Burnrate (macOS menu bar app)

## Summary

Users choose which figures appear next to the flame in the Mac status bar. Any combination of three values is allowed: window spend, the Cursor models included-pool percent, and the Other models included-pool percent. The panel header shows the same combination. Turning all three off leaves the flame alone and replaces **Hide amount in menu bar**.

Pool percents come from the existing billing-cycle rings (`IncludedPools`). They do not follow the timeline picker. Window spend stays the timeline total it is today.

## Settings

Three toggles in Settings → General, in this order:

| Toggle | Default |
|---|---|
| Window spend | On |
| Cursor models | Off |
| Other models | Off |

Any combination is valid, including all on and all off. A caption under the toggles says they choose what appears next to the flame, that the panel header shows those figures, and that turning all three off leaves the flame alone while the panel still shows window spend.

Remove the **Hide amount in menu bar** toggle.

### Persistence

Store three booleans in UserDefaults:

- `statusBarShowsWindowSpend`
- `statusBarShowsCursorModels`
- `statusBarShowsOtherModels`

Migrate once, when none of those keys exist yet:

- `hideAmountInMenuBar == true` → all three false
- otherwise → window spend true, both percents false

Write the new keys during that migration. The old hide toggle is no longer shown. `communityClientConfig().hideAmountInMenuBar` becomes true only when all three toggles are off, so the existing analytics field still means “the status bar is showing no numbers.” This change does not add community fields.

Changing a toggle redraws the status bar and header. It does not refetch usage.

## Status bar

One formatter builds the status text. Parts appear in fixed order — window spend, Cursor models, Other models — and disabled parts are omitted. A middle dot with spaces (` · `) separates the parts that remain.

| On | Text |
|---|---|
| Spend | `$12.40` |
| Cursor models | `72%` |
| Other models | `45%` |
| Spend + one pool | `$12.40 · 72%` |
| Both pools | `C 72% · O 45%` |
| All three | `$12.40 · C 72% · O 45%` |
| None | flame only, no text |

`C` is Cursor models and `O` is Other models. Those letters appear only when both percent toggles are on, including when one of those pools has no value (`C — · O 45%`). A single enabled percent has no letter.

Formatting rules:

- Spend uses `MoneyFormat.dollars`, same as today. Before the first completed fetch it is `$—.——`.
- A percent uses `IncludedPools.displayPercent` (rounded integer) plus `%`. `0` is `0%`. Values above 100 display as rounded, such as `120%`.
- An enabled pool with no value (still loading, last request failed and nothing was cached, or an unlimited plan) is `—`, with the `C` / `O` prefix when both percent toggles are on.
- A failed pool refresh keeps the last `IncludedPools`, so the last percent stays on screen.

The flame, the filled flame on a spike, the dev-build dot, and the warning triangle stay driven by dollar spend and errors.

The `--status` command keeps printing the window dollar total and does not follow these toggles.

Accessibility label names every visible part in full, for example “Window spend $12.40, Cursor models 72 percent used, Other models not loaded.”

## Header

The header shows the same enabled parts, in the same order, with the same text as the status bar.

- The first enabled part is the large hero (the current 34pt dollar style).
- Each further enabled part sits on that same row, smaller, separated the same way.
- The spinner stays beside the hero.
- When at least one percent is enabled, a caption under the hero names each enabled pool: “Cursor models used this cycle” and “Other models used this cycle.” Spend-only has no new caption.
- When window spend is enabled, that dollar figure is the timeline total, and the burn pill stays beside it.
- When window spend is off, the timeline total still appears smaller under the caption, with the burn pill beside those dollars, so the lists under the timeline still have their total.

Spend-only matches today’s header. When all three toggles are off, the status bar shows the flame only and the header stays that same window-spend layout, which is how **Hide amount in menu bar** works today. Timeline picker, Community button, rings, sparkline, and tabs stay as they are.

## Testing

Cover the formatter and migration without UI tests:

- Each row of the status-bar table, plus all off.
- `0%`, a value that rounds (for example `72.4` → `72%`), and a value above 100.
- Both percents on with one pool missing → `C — · O 45%`. One percent on and missing → `—`.
- Spend before the first fetch → `$—.——`.
- Migration: missing new keys and hide true → all off; missing new keys and hide false → spend on only; existing new keys are left as stored.
- `communityClientConfig().hideAmountInMenuBar` is true only when all three toggles are off.

## Docs

Update the menu-bar row in `README.md` and the settings list in `CAPABILITIES.md`. Leave released sections in `Sources/Tokens/Resources/CHANGELOG.md` unchanged.

## Out of scope

- Refetching or changing how pool percents are parsed.
- Letting the percents follow Today / 24h / 7d.
- Changing `--status` output.
- Adding the new toggles as separate community analytics fields.
