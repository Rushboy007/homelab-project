import SwiftUI

struct NpmProxyHostCard: View {
    let proxyHost: NpmProxyHost
    let npmColor: Color
    let t: Translations

    private var statusColor: Color {
        if !proxyHost.isEnabled { return AppTheme.textMuted }
        return proxyHost.isOnline ? AppTheme.running : AppTheme.danger
    }

    private var statusLabel: String {
        if !proxyHost.isEnabled { return t.npmDisabled }
        return proxyHost.isOnline ? t.statusOnline : t.npmOffline
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 10, height: 10)

                    Text(proxyHost.primaryDomain)
                        .font(.body.bold())
                        .lineLimit(1)
                }

                Spacer()

                Text(statusLabel)
                    .font(.caption2.bold())
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            if proxyHost.domainNames.count > 1 {
                Text(proxyHost.domainNames.dropFirst().joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)
                    .lineLimit(1)
                    .padding(.top, 4)
            }

            HStack(spacing: 6) {
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textMuted)
                Text(proxyHost.forwardTarget)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)
            }
            .padding(.top, 10)

            HStack(spacing: 6) {
                if proxyHost.hasSSL {
                    featureChip(icon: "lock.fill", text: "SSL")
                }
                if proxyHost.http2Support == 1 {
                    featureChip(icon: "bolt.fill", text: "HTTP/2")
                }
                if proxyHost.cachingEnabled == 1 {
                    featureChip(icon: "arrow.triangle.2.circlepath", text: t.npmCache)
                }
                if proxyHost.blockExploits == 1 {
                    featureChip(icon: "shield.fill", text: t.npmSecurity)
                }
            }
            .padding(.top, 8)
        }
        .padding(14)
        .glassCard()
    }

    private func featureChip(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9))
            Text(text)
                .font(.caption2.weight(.medium))
        }
        .foregroundStyle(AppTheme.textMuted)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
