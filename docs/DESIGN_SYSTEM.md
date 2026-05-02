# Stax Design System

Operating manual for the Stax SwiftUI design system. Token spec is in
[`design-system-token-notes.md`](design-system-token-notes.md). This document
covers **how to use the system** — naming, accessibility, previews,
extension — for everyone working in `Stax/Design/`.

> **Platform**: iOS / SwiftUI only. The "web codebase" rules sometimes used
> elsewhere (Storybook, accessible HTML) don't apply — the iOS-equivalent
> obligations (`#Preview` blocks, SwiftUI accessibility modifiers) do.

## 1. Architecture

Three layers, top-down:

```
┌─────────────────────────────────────────────────────────┐
│  App screens  (Stax/Library/, Stax/Import/, …)          │
│      ↓ uses                                             │
│  Components  (Stax/Design/Components/Stax*.swift)       │
│      ↓ uses                                             │
│  Tokens      (Stax/Design/DesignTokens.swift)           │
└─────────────────────────────────────────────────────────┘
```

- **Tokens** are the only place raw values (hexes, point sizes, durations) live.
- **Components** consume tokens and expose typed APIs to screens.
- **Screens** consume components. Screens should never reach down to raw
  tokens for colors/spacing if a component covers the use case.

## 2. Token usage rules

### Always use semantic role aliases in views

`DesignTokens.Color.Role.*` describes **what the color does** (`bgSurface`,
`textSecondary`, `borderSubtle`, `focusRing`). The raw palette
(`Color.primary`, `Color.neutralBorder`) is the implementation detail
underneath — don't reach for it from view code.

```swift
// ✅ Correct
.background(DesignTokens.Color.Role.bgSurface)
.foregroundStyle(DesignTokens.Color.Role.textPrimary)
.overlay(stroke: DesignTokens.Color.Role.borderSubtle)

// ❌ Wrong — bypasses the semantic layer
.background(DesignTokens.Color.neutralSurface)
.foregroundStyle(DesignTokens.Color.primary)
```

The single exception is when the role you need does not yet exist — in
which case **add a new role alias to `Color.Role`** rather than reaching
through.

### Status colors get role aliases too

```swift
// ✅
.foregroundStyle(DesignTokens.Color.Role.textDanger)
.background(DesignTokens.Color.Role.bgWarningSubtle)

// ❌
.foregroundStyle(DesignTokens.Color.danger)
.background(DesignTokens.Color.warning.opacity(0.14))
```

### No raw hex, no raw `Color(red:...)`, no raw system colors

The token layer owns hexes. If you need a color that doesn't exist:

1. Add it to `DesignTokens.Color` (raw palette).
2. Add a `Color.Role.*` alias describing its purpose.
3. Use the role alias from your view.

A grep that returns hits is a bug:

```bash
grep -rE '#[0-9A-Fa-f]{6}|0x[0-9A-Fa-f]{6}|Color\(red:' Stax/Design/Components
```

### Spacing, radius, motion, typography — same rule

```swift
// ✅
.padding(DesignTokens.Spacing.lg)
.cornerRadius(DesignTokens.Radius.md)
.animation(.easeOut(duration: DesignTokens.Motion.fast), value: …)
.staxText(.h2)

// ❌
.padding(16)
.cornerRadius(12)
.animation(.easeOut(duration: 0.15), value: …)
.font(.system(size: 22, weight: .semibold))
```

A magic number in component code is a missing token. Add one.

## 3. Component anatomy

Every component file follows the same shape:

```swift
import SwiftUI

/// One-paragraph doc comment describing what it is, then a usage snippet.
///
/// ```swift
/// StaxFoo("…", isOn: $bar) { … }
/// ```
struct StaxFoo: View {
    enum Variant { … }   // if the component has variants
    enum Size    { … }   // if the component has sizes

    // stored properties

    init(…) { … }

    var body: some View { … }
}

// MARK: - Optional supporting types (ButtonStyle, ToggleStyle, etc.)

// MARK: - Previews
//
// State matrix below.
#Preview("State matrix") { … }
```

**Hard requirements** for every new component:

- Doc comment with at least one usage snippet.
- All visual values come from `DesignTokens`.
- Accessibility (see §4) — at minimum a label, often `.accessibilityElement`.
- `#Preview("State matrix")` showing default / selected / disabled / error
  / destructive / variants — whatever is applicable.
- Min touch target enforced (`.frame(minHeight: DesignTokens.A11y.minTouchTarget)`)
  on anything tappable.

### Variants vs. states vs. sizes

- **Variant** = visual treatment chosen at construction time and not expected
  to change (`.primary`, `.secondary`, `.destructive`). Encoded as an enum.
- **State** = transient condition that changes at runtime (`.default`,
  `.pressed`, `.focused`, `.selected`, `.disabled`). Encoded as
  `DesignTokens.InteractiveState` and applied through token lookup.
- **Size** = explicit sizing tier (`.small`, `.medium`, `.large`). Encoded as
  an enum with a `diameter`/`pointSize` accessor.

Compose them: `Variant × Size × State`. Don't conflate (e.g. don't make
`.disabled` a variant — disabled is the SwiftUI environment value
`.isEnabled = false`).

### Configuration via chainable methods

When a component has many optional knobs, expose them as chainable
`-> Self` methods rather than ballooning the initializer:

```swift
StaxButton("Save", action: save)
    .variant(.primary)
    .fillWidth()
```

Match the SwiftUI modifier idiom (`.padding(_)`, `.font(_)`).

## 4. Accessibility checklist

Run through this list for every new component. SwiftUI's defaults are
**not** sufficient for composite views — you have to opt in.

**Labels**
- Single-action button: SwiftUI's `Button("Title", action:)` infers the
  label from the title. Fine.
- Icon-only button: must call `.accessibilityLabel("…")`.
- Composite cards (icon + title + subtitle + badge): combine into one
  element with `.accessibilityElement(children: .combine)` or `.ignore` and
  set an explicit `.accessibilityLabel("…")` that reads naturally.
- Stat cards / numerical displays: combine "value" and "label" into one
  spoken phrase ("Cards: 48, trending up by 3"), don't let VoiceOver read
  them as two unrelated strings.

**Hidden decorations**
- Decorative SF Symbols inside a labelled control: `.accessibilityHidden(true)`.
  If the label is "Delete deck", VoiceOver should not also say "Image, trash."
- Trend arrows, chevrons, file-type glyphs — hide unless they're the only
  thing conveying meaning.

**Traits**
- Toggleable controls: `.accessibilityAddTraits(.isSelected)` when on.
- Buttons made out of non-Button views (e.g. `.onTapGesture`):
  `.accessibilityAddTraits(.isButton)`.
- Headings inside cards: `.accessibilityAddTraits(.isHeader)`.

**Custom controls**
- For switches/toggles built from primitives, prefer
  `.accessibilityRepresentation { Toggle(...) }` so VoiceOver gets the
  native semantics (e.g. "Switch button, on, double tap to toggle").

**Hit targets**
- 44pt minimum on every interactive element. Use
  `.frame(minHeight: DesignTokens.A11y.minTouchTarget)` (and `minWidth` for
  icon-only). The visual size can be smaller — pad the hit area, not the
  glyph.

**Verify**
- Turn on VoiceOver in the simulator. Tap-through every state shown in the
  preview. Each focused element should announce something useful and not
  duplicative.

### iOS doesn't have hover

Don't try to mock a hover state. iPhone has no pointer; iPad with a trackpad
gets system-level hover effects you don't author. The `InteractiveState`
enum includes `.hover` for forward-compatibility (Mac Catalyst), but its
visual treatment is a derived opacity from `.default` — see
`DesignTokens.Component.Button.Primary.bg(_:)`.

## 5. Preview / state matrix conventions

Every component ships exactly one `#Preview` titled `"State matrix"`. Use
the helpers in `_StatePreview.swift`:

- `StaxStateRow("Title") { … }` — for a horizontal row of variants.
- `StaxStateGrid("Title") { … }` — for a vertical group (use when the
  components are wide, like cards or rows).

Cover the states that exist for the component — don't fake the ones that
don't:

| State          | Render?                                                      |
|----------------|--------------------------------------------------------------|
| Default        | Always.                                                      |
| Selected       | If the component has selection (Chip, Toggle, Switch, Tabs). |
| Disabled       | If the component is interactive.                             |
| Error          | If the component has an error variant (Input).               |
| Destructive    | If the component has a destructive variant (Button).         |
| Pressed / hover | **Skip.** iOS has no hover; pressed is interaction-only and shows when the live preview is tapped. |

State that needs `@State` / bindings goes in a `private struct` host view at
the bottom of the file:

```swift
#Preview("State matrix") {
    StaxFooPreviewHost()
        .padding(DesignTokens.Spacing.xl)
        .background(DesignTokens.Color.Role.bgCanvas)
}

private struct StaxFooPreviewHost: View {
    @State private var selected = true
    var body: some View {
        StaxStateRow("Selected") { StaxFoo(isOn: $selected) }
    }
}
```

Background is always `DesignTokens.Color.Role.bgCanvas` so previews look
like real Stax screens, not raw white.

## 6. Adding a new component

1. Create `Stax/Design/Components/Stax<Name>.swift`.
2. Doc comment + usage snippet at the top.
3. Define variant / size / state enums if relevant.
4. Build the body using only `DesignTokens.*`. Add new tokens before
   reaching for raw values.
5. Wire accessibility per §4.
6. Add a `#Preview("State matrix")` per §5.
7. Build (`⌘B`) and verify the preview in Xcode.

The project uses `PBXFileSystemSynchronizedRootGroup`, so dropping the file
in `Stax/Design/Components/` is enough — no `project.pbxproj` edit needed.

## 7. Adding a new token

1. Open `Stax/Design/DesignTokens.swift`.
2. Add the raw value to the appropriate enum (`Color`, `Spacing`, `Radius`,
   `Shadow`, `Motion`, `A11y`, `Component.*`).
3. If the token is a color, **also add a `Color.Role.*` alias** describing
   its purpose. Component code consumes only role aliases.
4. Update `docs/design-system-token-notes.md` (the table near the top).
5. If the value was eyeballed from the design references, mark it
   `// UNCERTAIN — <why>` so a grep flags it for later precision.

## 8. Component inventory

### Atoms
- **`StaxButton`** — text/icon button. 4 variants × 3 states. Also exposes
  `StaxButtonStyle` for native `Button` use.
- **`StaxIconButton`** — icon-only circular button. 4 variants × 3 sizes.
  Always 44pt touch target via padded hit area.
- **`StaxBadge`** — non-interactive status pill. 6 styles
  (`brand/success/warning/danger/info/neutral`).
- **`StaxChip`** — interactive pill: read-only, selectable, or removable
  (three init flavors).
- **`StaxToggle`** — pill button that flips between selected/unselected
  (different from `StaxSwitch`'s slider).
- **`StaxSwitch`** — iOS-style track/thumb switch. Also exposes
  `StaxSwitchStyle` for native `Toggle`.
- **`StaxSegmentedControl`** — generic over `Hashable` selection value,
  uses `matchedGeometryEffect` for the thumb.
- **`StaxInput`** — `TextField` wrapper with leading icon, error state,
  `@FocusState` border treatment.
- **`StaxCard`** — surface container. Chainable padding, shadow, border.

### Navigation
- **`StaxBottomNavigation`** — generic over `Hashable` selection value, top
  hairline divider, fills SF Symbol on selection.

### Domain-flavored molecules
All take primitive params (no domain-model coupling).

- **`StaxDeckListItem`** — leading icon tile + title + subtitle + optional
  badge + chevron. Tappable.
- **`StaxFileImportCard`** — `State` enum (`pending` / `importing(progress)`
  / `success` / `failed(message)`) drives the icon, status, progress bar,
  and trailing cancel/retry control.
- **`StaxOfflineAIInfoCard`** — enabled vs. unavailable variants with sane
  default copy.
- **`StaxFlashcardReviewCard`** — question / answer / source plus four
  FSRS-rated buttons (`again` / `hard` / `good` / `easy`).
- **`StaxStudyCard`** — pre-reveal question card with optional progress and
  hint, full-width "Show Answer" CTA.
- **`StaxStatCard`** — value + label + optional icon + trend chip.
  6 accents × 3 trend directions.
- **`StaxExportChip`** — preset `.anki/.csv/.pdf/.json` plus
  `.custom(label:icon:)`. Always shows download glyph.
- **`StaxSourceCitationRow`** — file name + em-dash-joined
  source/subject/page chain, optional open action.

## 9. Out of scope (today)

- **Dark mode**. The design references only show light mode. When dark
  arrives, the only file that needs to change is `DesignTokens.swift` —
  replace each `Color.Role.*` with a dynamic
  `Color(uiColor: .init { trait in ... })`.
- **Asset Catalog colors**. Tokens return `SwiftUI.Color` directly.
- **Localization of role-derived strings** (e.g. accessibility labels
  composed in code). When localization arrives, route them through
  `String(localized:)`.
- **Macros for token boilerplate**. Currently we accept the verbose
  `DesignTokens.Color.Role.textPrimary` reference at call sites; if it
  becomes painful, consider a `@Token` property wrapper or short-form
  `Tok.text.primary` namespace.
