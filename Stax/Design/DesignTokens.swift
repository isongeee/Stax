import SwiftUI

// MARK: - DesignTokens

/// Single source of truth for the Stax visual language.
/// Source: `design-reference/02–08 *.png`. Values flagged `// UNCERTAIN`
/// were estimated from the design images and should be replaced when the
/// Figma source-of-truth is available. See `docs/design-system-token-notes.md`.
enum DesignTokens {

    // MARK: Color

    /// Raw palette swatches. Prefer `Color.Role` aliases in view code.
    enum Color {

        // Brand
        static let primary       = SwiftUI.Color(hex: 0x2563EB)
        static let deepNavy      = SwiftUI.Color(hex: 0x0F2540) // UNCERTAIN — closest match from image
        static let skyBlue       = SwiftUI.Color(hex: 0x7DBEFF) // UNCERTAIN
        static let teal          = SwiftUI.Color(hex: 0x2DD4BF) // UNCERTAIN

        // Status
        static let success       = SwiftUI.Color(hex: 0x22C55E)
        static let warning       = SwiftUI.Color(hex: 0xF59E0B)
        static let danger        = SwiftUI.Color(hex: 0xEF4444)
        static let info          = SwiftUI.Color(hex: 0x3B82F6)
        static let accentPurple  = SwiftUI.Color(hex: 0xA855F7) // UNCERTAIN

        // Neutrals
        static let neutralBackground   = SwiftUI.Color(hex: 0xF8FAFC)
        static let neutralSurface      = SwiftUI.Color(hex: 0xFFFFFF)
        static let neutralSurfaceAlt   = SwiftUI.Color(hex: 0xF1F5F9)
        static let neutralBorder       = SwiftUI.Color(hex: 0xE2E8F0)
        static let neutralTextPrimary  = SwiftUI.Color(hex: 0x0F172A)
        static let neutralTextSecondary = SwiftUI.Color(hex: 0x64748B)
        static let neutralDisabled     = SwiftUI.Color(hex: 0xCBD5E1)

        // MARK: Role aliases — what view code should use

        /// Semantic role aliases. Use these instead of raw palette names so
        /// future theming (dark mode, brand variants) only touches this file.
        enum Role {
            // Surfaces
            static let bgCanvas        = neutralBackground
            static let bgSurface       = neutralSurface
            static let bgElevated      = neutralSurface
            static let bgMuted         = neutralSurfaceAlt

            // Text
            static let textPrimary     = neutralTextPrimary
            static let textSecondary   = neutralTextSecondary
            static let textDisabled    = neutralDisabled
            static let textInverse     = neutralSurface
            static let textOnPrimary   = neutralSurface
            static let textLink        = primary

            // Borders / dividers
            static let borderSubtle    = neutralBorder
            static let borderStrong    = neutralTextSecondary
            static let focusRing       = primary

            // Status text/icon
            static let textSuccess     = success
            static let textWarning     = warning
            static let textDanger      = danger
            static let textInfo        = info

            // Status icons (alias of text*; use whichever name reads better at the call site)
            static let iconBrand       = primary
            static let iconSuccess     = success
            static let iconWarning     = warning
            static let iconDanger      = danger
            static let iconInfo        = info

            // Subtle tinted backgrounds — for icon tiles, badge fills, callouts.
            // Opacities are UNCERTAIN — derived to read at WCAG AA against role text colors.
            static let bgBrandSubtle   = primary.opacity(0.10)
            static let bgSuccessSubtle = success.opacity(0.12)
            static let bgWarningSubtle = warning.opacity(0.14)
            static let bgDangerSubtle  = danger.opacity(0.10)
            static let bgInfoSubtle    = info.opacity(0.10)
        }
    }

    // MARK: Typography
    //
    // Family: SF Pro on Apple platforms (system font); Inter is the
    // cross-platform mirror. Sizes/weights from `03 — Typography.png`.
    // Line heights are expressed as multipliers of the font size; SwiftUI
    // exposes them via `.lineSpacing(...)` (extra spacing) — apply with
    // `Text(...).font(DesignTokens.Typography.body.font).lineSpacing(...)`
    // or use the `.staxText(.body)` helper at the bottom of this file.
    enum Typography {

        struct Style {
            let font: Font
            let size: CGFloat
            let lineHeight: CGFloat
            /// Extra spacing between lines, for SwiftUI's `.lineSpacing(_:)`.
            var lineSpacing: CGFloat { max(0, lineHeight - size) }

            // Scale — declared on `Style` so view code can use leading-dot syntax:
            // `.staxText(.h2)`, `Text("…").font(DesignTokens.Typography.body.font)`.
            static let display   = Style(font: .system(size: 34, weight: .bold,     design: .default), size: 34, lineHeight: 40)
            static let h1        = Style(font: .system(size: 28, weight: .semibold, design: .default), size: 28, lineHeight: 34)
            static let h2        = Style(font: .system(size: 22, weight: .semibold, design: .default), size: 22, lineHeight: 28)
            static let h3        = Style(font: .system(size: 18, weight: .semibold, design: .default), size: 18, lineHeight: 24) // UNCERTAIN — H3 not labelled in image
            static let body      = Style(font: .system(size: 16, weight: .regular,  design: .default), size: 16, lineHeight: 24)
            static let bodySmall = Style(font: .system(size: 14, weight: .regular,  design: .default), size: 14, lineHeight: 20)
            static let label     = Style(font: .system(size: 13, weight: .medium,   design: .default), size: 13, lineHeight: 18) // UNCERTAIN
            static let caption   = Style(font: .system(size: 12, weight: .regular,  design: .default), size: 12, lineHeight: 16)
        }

        // Top-level aliases (kept for `DesignTokens.Typography.body` call sites).
        static let display   = Style.display
        static let h1        = Style.h1
        static let h2        = Style.h2
        static let h3        = Style.h3
        static let body      = Style.body
        static let bodySmall = Style.bodySmall
        static let label     = Style.label
        static let caption   = Style.caption

        /// Numeric weight references mirroring the design system.
        enum Weight {
            static let regular:  Font.Weight = .regular   // 400
            static let medium:   Font.Weight = .medium    // 500
            static let semibold: Font.Weight = .semibold  // 600
            static let bold:     Font.Weight = .bold      // 700
        }
    }

    // MARK: Spacing — 8pt scale (`04 — Layout, Grid & Spacing.png`)

    enum Spacing {
        static let xxs:  CGFloat = 2  // UNCERTAIN — not visible in image; useful for hairline insets
        static let xs:   CGFloat = 4
        static let sm:   CGFloat = 8
        static let md:   CGFloat = 12
        static let lg:   CGFloat = 16
        static let xl:   CGFloat = 24
        static let xxl:  CGFloat = 32
        static let xxxl: CGFloat = 48
        static let huge: CGFloat = 64
    }

    // MARK: Corner radius (`04 — Layout, Grid & Spacing.png`)

    enum Radius {
        static let none: CGFloat = 0
        static let xs:   CGFloat = 4
        static let sm:   CGFloat = 8
        static let md:   CGFloat = 12   // default card radius per `06 — Components.png`
        static let lg:   CGFloat = 16
        static let xl:   CGFloat = 24
        static let pill: CGFloat = 999
    }

    // MARK: Shadow / elevation (`04 — Layout, Grid & Spacing.png`)

    enum Shadow {
        // All values UNCERTAIN — derived visually, not measured.
        static let e1 = ShadowToken(color: .black.opacity(0.06), radius: 2,  x: 0, y: 1)
        static let e2 = ShadowToken(color: .black.opacity(0.10), radius: 8,  x: 0, y: 2)
        static let e3 = ShadowToken(color: .black.opacity(0.16), radius: 24, x: 0, y: 8)
    }

    // MARK: Motion (`08 — Iconography, Illustration & Accessibility.png`)
    // Durations UNCERTAIN — sheet doesn't quantify; using common iOS defaults.

    enum Motion {
        static let fast: Double = 0.15
        static let base: Double = 0.25
        static let slow: Double = 0.40
    }

    // MARK: Accessibility (`08 — Iconography, Illustration & Accessibility.png`)

    enum A11y {
        /// Apple HIG matches the sheet's "Large Tap Targets" guidance.
        static let minTouchTarget: CGFloat = 44
        static let minContrastBody: Double = 4.5
        static let minContrastLarge: Double = 3.0
    }

    // MARK: Component-state tokens (`05 — Controls.png`)

    /// Visual state of an interactive surface. Hover applies on pointer
    /// devices (iPad with trackpad / Mac Catalyst) only.
    enum InteractiveState {
        case `default`, hover, pressed, focused, selected, disabled
    }

    enum Component {

        enum Button {

            enum Primary {
                static func bg(_ state: InteractiveState) -> SwiftUI.Color {
                    switch state {
                    case .default, .focused, .selected: return Color.primary
                    case .hover:    return Color.primary.opacity(0.92) // UNCERTAIN — derived, not measured
                    case .pressed:  return Color.primary.opacity(0.85) // UNCERTAIN — derived
                    case .disabled: return Color.neutralDisabled
                    }
                }
                static let fg: SwiftUI.Color = Color.Role.textOnPrimary
                static let fgDisabled: SwiftUI.Color = Color.Role.textInverse.opacity(0.7) // UNCERTAIN
            }

            enum Secondary {
                static func bg(_ state: InteractiveState) -> SwiftUI.Color {
                    switch state {
                    case .default:  return Color.neutralSurface
                    case .hover:    return Color.neutralSurfaceAlt // UNCERTAIN
                    case .pressed:  return Color.neutralBorder      // UNCERTAIN
                    case .focused, .selected: return Color.neutralSurfaceAlt
                    case .disabled: return Color.neutralSurface
                    }
                }
                static func border(_ state: InteractiveState) -> SwiftUI.Color {
                    switch state {
                    case .focused: return Color.primary
                    case .disabled: return Color.neutralBorder
                    default: return Color.neutralBorder
                    }
                }
                static let fg: SwiftUI.Color = Color.Role.textPrimary
                static let fgDisabled: SwiftUI.Color = Color.neutralDisabled
            }

            /// Tertiary / "ghost" button — text-only with no chrome until pressed.
            enum Tertiary {
                static func bg(_ state: InteractiveState) -> SwiftUI.Color {
                    switch state {
                    case .hover:    return Color.neutralSurfaceAlt        // UNCERTAIN
                    case .pressed:  return Color.neutralBorder.opacity(0.6) // UNCERTAIN
                    default:        return .clear
                    }
                }
                static let fg: SwiftUI.Color = Color.primary
                static let fgDisabled: SwiftUI.Color = Color.neutralDisabled
            }

            enum Danger {
                static func bg(_ state: InteractiveState) -> SwiftUI.Color {
                    switch state {
                    case .default, .focused, .selected: return Color.danger
                    case .hover:    return Color.danger.opacity(0.92) // UNCERTAIN — derived
                    case .pressed:  return Color.danger.opacity(0.85) // UNCERTAIN — derived
                    case .disabled: return Color.neutralDisabled
                    }
                }
                static let fg: SwiftUI.Color = Color.Role.textOnPrimary
            }
        }

        enum Input {
            static let bg: SwiftUI.Color = Color.neutralSurface
            static func border(_ state: InteractiveState) -> SwiftUI.Color {
                switch state {
                case .focused:  return Color.primary
                case .disabled: return Color.neutralBorder
                case .selected: return Color.primary
                default:        return Color.neutralBorder
                }
            }
            /// Use when the field is in an error state (validation failed).
            static let borderError: SwiftUI.Color = Color.danger
            static let placeholderFg: SwiftUI.Color = Color.neutralTextSecondary
            static let textFg: SwiftUI.Color = Color.Role.textPrimary
        }

        enum Chip {
            static func bg(_ state: InteractiveState) -> SwiftUI.Color {
                switch state {
                case .selected: return Color.primary.opacity(0.10) // UNCERTAIN — derived
                case .disabled: return Color.neutralSurfaceAlt
                default:        return Color.neutralSurfaceAlt
                }
            }
            static func fg(_ state: InteractiveState) -> SwiftUI.Color {
                switch state {
                case .selected: return Color.primary
                case .disabled: return Color.neutralDisabled
                default:        return Color.Role.textPrimary
                }
            }
            static func border(_ state: InteractiveState) -> SwiftUI.Color {
                state == .selected ? Color.primary : Color.neutralBorder
            }
        }

        enum Card {
            static let bg: SwiftUI.Color = Color.neutralSurface
            static let border: SwiftUI.Color = Color.neutralBorder
            static let radius: CGFloat = Radius.md
            static let padding: CGFloat = Spacing.lg
            static let shadow: ShadowToken = Shadow.e1
        }
    }
}

// MARK: - ShadowToken + helpers

struct ShadowToken {
    let color: SwiftUI.Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

extension View {
    /// Applies a `ShadowToken` from `DesignTokens.Shadow`.
    func staxShadow(_ token: ShadowToken) -> some View {
        shadow(color: token.color, radius: token.radius, x: token.x, y: token.y)
    }

    /// Applies a `DesignTokens.Typography.Style` (font + line spacing).
    func staxText(_ style: DesignTokens.Typography.Style) -> some View {
        font(style.font).lineSpacing(style.lineSpacing)
    }
}

// MARK: - Color(hex:) initializer
//
// SwiftUI does not provide a hex initializer out of the box.

private extension SwiftUI.Color {
    init(hex: UInt32, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >>  8) & 0xFF) / 255.0
        let b = Double( hex        & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
