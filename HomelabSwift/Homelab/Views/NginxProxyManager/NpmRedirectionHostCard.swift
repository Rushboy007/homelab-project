import SwiftUI

struct NpmRedirectionHostCard: View {
    let host: NpmRedirectionHost
    let npmColor: Color
    let t: Translations

    private var statusColor: Color {
        host.isEnabled ? AppTheme.running : AppTheme.textMuted
    }

    private var statusLabel: String {
        host.isEnabled ? t.npmEnabled : t.npmDisabled
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 10, height: 10)

                    Text(host.primaryDomain)
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

            if host.domainNames.count > 1 {
                Text(host.domainNames.dropFirst().joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)
                    .lineLimit(1)
                    .padding(.top, 4)
            }

            HStack(spacing: 6) {
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textMuted)

                Text("\(host.forwardHttpCode)")
                    .font(.caption.bold())
                    .foregroundStyle(npmColor)

                Image(systemName: "arrow.right")
                    .font(.system(size: 8))
                    .foregroundStyle(AppTheme.textMuted)

                Text("\(host.forwardScheme)://\(host.forwardDomainName)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)
                    .lineLimit(1)
            }
            .padding(.top, 10)

            HStack(spacing: 6) {
                if host.hasSSL {
                    featureChip(icon: "lock.fill", text: "SSL")
                }
                if host.http2Support == 1 {
                    featureChip(icon: "bolt.fill", text: "HTTP/2")
                }
                if host.blockExploits == 1 {
                    featureChip(icon: "shield.fill", text: t.npmSecurity)
                }
                if host.preservePath == 1 {
                    featureChip(icon: "arrow.turn.down.right", text: t.npmPreservePath)
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
