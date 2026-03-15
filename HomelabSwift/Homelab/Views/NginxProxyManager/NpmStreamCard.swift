import SwiftUI

struct NpmStreamCard: View {
    let stream: NpmStream
    let npmColor: Color
    let t: Translations

    private var statusColor: Color {
        if !stream.isEnabled { return AppTheme.textMuted }
        return stream.isOnline ? AppTheme.running : AppTheme.danger
    }

    private var statusLabel: String {
        if !stream.isEnabled { return t.npmDisabled }
        return stream.isOnline ? t.statusOnline : t.npmOffline
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 10, height: 10)

                    Text(":\(stream.incomingPort)")
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

            HStack(spacing: 6) {
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textMuted)
                Text("\(stream.forwardingHost):\(stream.forwardingPort)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)
            }
            .padding(.top, 10)

            HStack(spacing: 6) {
                if stream.tcpForwarding == 1 {
                    protocolChip(text: "TCP")
                }
                if stream.udpForwarding == 1 {
                    protocolChip(text: "UDP")
                }
            }
            .padding(.top, 8)
        }
        .padding(14)
        .glassCard()
    }

    private func protocolChip(text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(npmColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(npmColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
