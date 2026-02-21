import SwiftUI

// Maps to components/SkeletonLoader.tsx

struct SkeletonLoader: View {
    var height: CGFloat = 80
    var cornerRadius: CGFloat = AppTheme.smallRadius
    @State private var isAnimating = false

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.gray.opacity(isAnimating ? 0.25 : 0.1))
            .frame(height: height)
            .animation(
                .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear { isAnimating = true }
    }
}

// MARK: - Stat card skeleton

struct SkeletonStatCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SkeletonLoader(height: 12, cornerRadius: 6)
                .frame(width: 80)
            SkeletonLoader(height: 24, cornerRadius: 6)
                .frame(width: 120)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.innerPadding)
        .glassCard()
    }
}

// MARK: - List row skeleton

struct SkeletonRow: View {
    var body: some View {
        HStack(spacing: 12) {
            SkeletonLoader(height: 44, cornerRadius: 8)
                .frame(width: 44)
            VStack(alignment: .leading, spacing: 6) {
                SkeletonLoader(height: 14, cornerRadius: 6)
                    .frame(maxWidth: .infinity)
                SkeletonLoader(height: 10, cornerRadius: 6)
                    .frame(width: 140)
            }
        }
        .padding(AppTheme.innerPadding)
        .glassCard()
    }
}
