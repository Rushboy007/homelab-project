import SwiftUI

// Maps to components/StatCard.tsx

struct GlassStatCard: View {
    let title: String
    let value: String
    var icon: String? = nil
    var iconColor: Color = AppTheme.accent
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption.bold())
                        .foregroundStyle(iconColor)
                }
                Text(title)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }

            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.innerPadding)
        .glassCard()
    }
}

// MARK: - Progress Stat Card (for CPU/Memory/Disk)

struct GlassProgressCard: View {
    let title: String
    let value: Double    // 0.0 – 100.0
    var icon: String? = nil
    var color: Color = AppTheme.accent
    var subtitle: String? = nil

    private var progressColor: Color {
        if value > 90 { return AppTheme.danger }
        if value > 75 { return AppTheme.warning }
        return color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption.bold())
                        .foregroundStyle(progressColor)
                }
                Text(title)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Text(Formatters.formatPercent(value))
                    .font(.caption.bold())
                    .foregroundStyle(progressColor)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white.opacity(0.1))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor.gradient)
                        .frame(width: geo.size.width * CGFloat(min(value, 100)) / 100, height: 6)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: value)
                }
            }
            .frame(height: 6)

            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textMuted)
            }
        }
        .padding(AppTheme.innerPadding)
        .glassCard()
    }
}
