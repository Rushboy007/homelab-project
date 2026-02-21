import SwiftUI

// Maps to components/StatusBadge.tsx

struct StatusBadge: View {
    let status: String
    var compact: Bool = false

    private var color: Color {
        AppTheme.statusColor(for: status)
    }

    var body: some View {
        HStack(spacing: compact ? 4 : 6) {
            Circle()
                .fill(color)
                .frame(width: compact ? 6 : 8, height: compact ? 6 : 8)

            if !compact {
                Text(status.capitalized)
                    .font(.caption.bold())
                    .foregroundStyle(color)
            }
        }
        .padding(.horizontal, compact ? 6 : 10)
        .padding(.vertical, compact ? 3 : 4)
        .modifier(GlassEffectModifier(cornerRadius: AppTheme.pillRadius, tint: color.opacity(0.2), interactive: false))
    }
}

// MARK: - Beszel system status

struct SystemStatusBadge: View {
    let isOnline: Bool

    var body: some View {
        StatusBadge(status: isOnline ? "up" : "down")
    }
}
