# Stax Design Token Notes

Companion to `Stax/Design/DesignTokens.swift`. Documents where each token came
from, which values are confirmed vs. estimated, and how to consume tokens from
SwiftUI views.

> **Format note:** the original spec called for `src/design/tokens.ts` and
> `tokens.json`. Stax is a Swift-only iOS project with no web surface, so the
> token spec lives in Swift. If a cross-platform export is needed later, run
> Style Dictionary against a JSON mirror generated from this file.

## Source of truth

All values were extracted from the design reference images shipped in
`design-reference/`:

| Image                                                  | Drives                                  |
| ------------------------------------------------------ | --------------------------------------- |
| `02 — Color System.png`                                | `Color.*`, `Color.Role.*`               |
| `03 — Typography.png`                                  | `Typography.*`                          |
| `04 — Layout, Grid & Spacing.png`                      | `Spacing.*`, `Radius.*`, `Shadow.*`     |
| `05 — Controls.png`                                    | `Component.Button/Input/Chip` states    |
| `06 — Components.png`                                  | `Component.Card` defaults               |
| `08 — Iconography, Illustration & Accessibility.png`   | `A11y.*`, `Motion.*`                    |

Pages `01` (brand overview) and `07` (screen templates) inform principles and
patterns but contribute no new atomic tokens.

## Naming convention

Two-tier naming:

1. **Raw palette** — `DesignTokens.Color.primary`, `Color.deepNavy`, etc.
   Match the swatch labels in the design system 1:1. Don't reach for these
   from view code unless you specifically need that brand swatch.
2. **Role aliases** — `DesignTokens.Color.Role.bgCanvas`,
   `Role.textPrimary`, `Role.borderSubtle`. Describe *what the color does*,
   not *what it looks like*. Prefer these in views — when dark mode or a
   brand variant arrives, only `Color.Role` needs to change.

Same idea applies elsewhere: spacing/radius use t-shirt sizes
(`Spacing.lg`, `Radius.md`), shadow uses elevation levels (`Shadow.e1`),
and component-state tokens take a state enum
(`Component.Button.Primary.bg(.pressed)`).

## Confirmed vs. UNCERTAIN values

| Token                                  | Status      | Note                                                                 |
| -------------------------------------- | ----------- | -------------------------------------------------------------------- |
| `Color.primary` `#2563EB`              | confirmed   | Hex visible in `02 — Color System.png`                               |
| `Color.deepNavy` `#0F2540`             | UNCERTAIN   | Closest match from image; verify against Figma                       |
| `Color.skyBlue` `#7DBEFF`              | UNCERTAIN   | Eyeballed                                                            |
| `Color.teal` `#2DD4BF`                 | UNCERTAIN   | Eyeballed                                                            |
| `Color.success/warning/danger/info`    | confirmed   | Tailwind-style hexes legible in image                                |
| `Color.accentPurple` `#A855F7`         | UNCERTAIN   | Eyeballed                                                            |
| Neutrals (background → disabled)       | confirmed   | Hexes legible in image                                               |
| `Typography.h3`                        | UNCERTAIN   | H3 row not labelled in `03 — Typography.png`; size/weight inferred   |
| `Typography.label`                     | UNCERTAIN   | Size 13 / medium guessed from "Label" specimen                       |
| `Spacing.xxs = 2`                      | UNCERTAIN   | Not in image; included for hairline insets                           |
| `Shadow.e1/e2/e3`                      | UNCERTAIN   | Offsets/blur/alpha derived visually, not measured                    |
| `Motion.fast/base/slow`                | UNCERTAIN   | Sheet doesn't quantify; using common iOS defaults                    |
| Button hover/pressed deltas            | UNCERTAIN   | Computed as opacity multipliers off the base color                   |

Every UNCERTAIN value is also flagged with a `// UNCERTAIN` comment in
`DesignTokens.swift` so a grep gives you the full to-do list.

## How to consume from SwiftUI

```swift
import SwiftUI

struct DeckCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Biology Chapter 4")
                .staxText(.h2)
                .foregroundStyle(DesignTokens.Color.Role.textPrimary)

            Text("48 cards · 84% retention")
                .staxText(.bodySmall)
                .foregroundStyle(DesignTokens.Color.Role.textSecondary)
        }
        .padding(DesignTokens.Component.Card.padding)
        .background(DesignTokens.Component.Card.bg)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Component.Card.radius)
                .stroke(DesignTokens.Component.Card.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Component.Card.radius))
        .staxShadow(DesignTokens.Component.Card.shadow)
    }
}
```

State-aware controls take an `InteractiveState`:

```swift
Button("Generate flashcards") { /* ... */ }
    .padding(.vertical, DesignTokens.Spacing.md)
    .padding(.horizontal, DesignTokens.Spacing.lg)
    .frame(minHeight: DesignTokens.A11y.minTouchTarget)
    .foregroundStyle(DesignTokens.Component.Button.Primary.fg)
    .background(DesignTokens.Component.Button.Primary.bg(.default))
    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
```

## Updating tokens

When the Figma source-of-truth becomes available:

1. Open `Stax/Design/DesignTokens.swift` and search for `// UNCERTAIN`.
2. Replace each value with the exact spec, then delete the comment.
3. Update the table above so the doc matches the code.

Avoid hard-coding hexes or magic numbers in views — if you need a value that
isn't in `DesignTokens`, add it here first.

## Out of scope

- **Asset catalog colors** — none added. The token enum returns `SwiftUI.Color`
  values directly, which is sufficient for a single-theme app.
- **Dark Mode variants** — design refs only show light mode. When dark
  arrives, replace each `Color.Role.*` definition with a dynamic
  `Color(uiColor: .init { trait in ... })` and the rest of the app will
  pick it up.
- **View modifiers beyond `.staxShadow` / `.staxText`** — keep the token
  layer thin; richer styles belong in dedicated view types under
  `Stax/Design/` later.
