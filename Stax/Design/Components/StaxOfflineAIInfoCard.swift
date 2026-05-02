import SwiftUI

/// "Offline AI Enabled" info card from `06 — Components.png`. A reassuring
/// status card communicating that the local model is ready and data is
/// staying on-device.
///
/// ```swift
/// StaxOfflineAIInfoCard(isEnabled: true)
/// // or with a custom message
/// StaxOfflineAIInfoCard(
///     isEnabled: false,
///     title: "On-device AI unavailable",
///     description: "Your device doesn't meet the minimum requirements."
/// )
/// ```
struct StaxOfflineAIInfoCard: View {

    private let isEnabled: Bool
    private let title: String
    private let description: String
    private let action: (label: String, perform: () -> Void)?

    init(
        isEnabled: Bool = true,
        title: String? = nil,
        description: String? = nil,
        action: (label: String, perform: () -> Void)? = nil
    ) {
        self.isEnabled = isEnabled
        self.title = title ?? (isEnabled ? "Offline AI Enabled" : "Offline AI Unavailable")
        self.description = description ?? (isEnabled
            ? "Stax works without internet. Your data stays on-device, always."
            : "Connect to the internet or check your model download to continue.")
        self.action = action
    }

    var body: some View {
        StaxCard {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(accentBgSubtle)
                        .frame(width: 44, height: 44)
                    Image(systemName: isEnabled ? "wifi.slash" : "exclamationmark.triangle.fill")
                        .imageScale(.large)
                        .foregroundStyle(accentColor)
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Text(title)
                            .staxText(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(DesignTokens.Color.Role.textPrimary)
                        StaxBadge(isEnabled ? "Ready" : "Offline",
                                  style: isEnabled ? .success : .warning)
                    }
                    Text(description)
                        .staxText(.bodySmall)
                        .foregroundStyle(DesignTokens.Color.Role.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let action {
                        StaxButton(action.label, action: action.perform)
                            .variant(.tertiary)
                            .padding(.top, DesignTokens.Spacing.xs)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(title). \(description)")
    }

    private var accentColor: Color {
        isEnabled ? DesignTokens.Color.Role.iconSuccess : DesignTokens.Color.Role.iconWarning
    }

    private var accentBgSubtle: Color {
        isEnabled ? DesignTokens.Color.Role.bgSuccessSubtle : DesignTokens.Color.Role.bgWarningSubtle
    }
}

// MARK: - Previews

#Preview("State matrix") {
    ScrollView {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            StaxStateGrid("Enabled (default copy)") {
                StaxOfflineAIInfoCard(isEnabled: true)
            }
            StaxStateGrid("Enabled, with action") {
                StaxOfflineAIInfoCard(
                    isEnabled: true,
                    action: (label: "Manage model", perform: {})
                )
            }
            StaxStateGrid("Unavailable") {
                StaxOfflineAIInfoCard(isEnabled: false)
            }
            StaxStateGrid("Unavailable, with action") {
                StaxOfflineAIInfoCard(
                    isEnabled: false,
                    description: "Connect to the internet to download the on-device model.",
                    action: (label: "Download model", perform: {})
                )
            }
        }
        .padding(DesignTokens.Spacing.xl)
    }
    .background(DesignTokens.Color.Role.bgCanvas)
}

