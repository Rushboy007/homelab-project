import SwiftUI

struct NpmCertificateCard: View {
    let certificate: NpmCertificate
    let npmColor: Color
    let t: Translations
    let inUse: Bool
    var onRenew: (() -> Void)?
    var onDelete: (() -> Void)?

    private var expiryColor: Color {
        certificate.isExpired ? AppTheme.danger : AppTheme.running
    }

    private var providerLabel: String {
        certificate.isLetsEncrypt ? t.npmLetsencrypt : t.npmCustomCert
    }

    private var formattedExpiry: String? {
        guard let expiresOn = certificate.expiresOn else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = formatter.date(from: expiresOn)
        if date == nil {
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: expiresOn)
        }
        guard let parsed = date else { return nil }
        let display = DateFormatter()
        display.dateStyle = .medium
        display.timeStyle = .none
        return display.string(from: parsed)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: certificate.isLetsEncrypt ? "lock.shield.fill" : "lock.fill")
                    .font(.title3)
                    .foregroundStyle(npmColor)
                    .frame(width: 32, height: 32)
                    .background(npmColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(certificate.niceName.isEmpty ? certificate.primaryDomain : certificate.niceName)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)

                    Text(providerLabel)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textMuted)
                        .lineLimit(1)
                }

                Spacer()

                if inUse {
                    Text("In Use")
                        .font(.caption2.bold())
                        .foregroundStyle(AppTheme.running)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppTheme.running.opacity(0.12), in: Capsule())
                }
            }

            if !certificate.domainNames.isEmpty {
                Text(certificate.domainNames.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)
                    .lineLimit(2)
                    .padding(.top, 4)
            }

            HStack {
                if certificate.isExpired {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                        Text(t.npmExpired)
                            .font(.caption.bold())
                    }
                    .foregroundStyle(AppTheme.danger)
                } else if let expiry = formattedExpiry {
                    Text(String(format: t.npmExpires, expiry))
                        .font(.caption)
                        .foregroundStyle(AppTheme.running)
                }

                Spacer()

                if certificate.isLetsEncrypt, let onRenew {
                    Button {
                        onRenew()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption2)
                            Text(t.npmRenew)
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(npmColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(npmColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                if let onDelete {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(AppTheme.danger)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppTheme.danger.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 10)
        }
        .padding(14)
        .glassCard()
    }
}
