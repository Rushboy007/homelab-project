import SwiftUI

// Maps to components/OfflineBanner.tsx

struct OfflineBanner: View {
    let serviceName: String
    let onReconnect: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.subheadline.bold())
                .foregroundStyle(AppTheme.stopped)

            Text("\(serviceName) unreachable")
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer()

            Button("Reconnect", action: onReconnect)
                .font(.caption.bold())
                .buttonStyle(.glass)
                .controlSize(.small)
        }
        .padding(AppTheme.innerPadding)
        .modifier(GlassEffectModifier(
            cornerRadius: AppTheme.smallRadius,
            tint: AppTheme.stopped.opacity(0.2),
            interactive: false
        ))
        .padding(.horizontal, AppTheme.padding)
        .padding(.top, 8)
    }
}
