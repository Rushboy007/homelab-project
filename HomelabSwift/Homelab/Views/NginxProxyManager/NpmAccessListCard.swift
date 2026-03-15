import SwiftUI

struct NpmAccessListCard: View {
    let accessList: NpmAccessList
    let t: Translations
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(accessList.name)
                    .font(.body.bold())
                    .lineLimit(1)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppTheme.textMuted.opacity(0.5))
            }

            let usersCount = accessList.items?.count ?? 0
            let clientsCount = accessList.clients?.count ?? 0
            Text("\(usersCount) \(t.npmAccessListUsers) • \(clientsCount) \(t.npmAccessListRules)")
                .font(.caption2)
                .foregroundStyle(AppTheme.textMuted)
        }
        .padding(14)
        .glassCard()
        .contentShape(Rectangle())
        .onTapGesture { onEdit() }
    }
}
