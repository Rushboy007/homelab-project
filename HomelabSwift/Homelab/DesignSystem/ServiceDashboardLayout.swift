import SwiftUI

// Maps to components/ServiceDashboardLayout.tsx
// Generic wrapper providing: loading state, error state, pull-to-refresh, offline banner.

struct ServiceDashboardLayout<Content: View>: View {
    let serviceType: ServiceType
    let isLoading: Bool
    var error: Error? = nil
    let onRefresh: () async -> Void
    @ViewBuilder let content: () -> Content

    @Environment(ServicesStore.self) private var servicesStore
    @State private var refreshID = UUID()

    var isUnreachable: Bool {
        servicesStore.isReachable(serviceType) == false
    }

    var body: some View {
        ZStack(alignment: .top) {
            if isLoading {
                loadingView
            } else if let error {
                errorView(error)
            } else {
                ScrollView {
                    LazyVStack(spacing: AppTheme.gridSpacing) {
                        content()
                    }
                    .padding(AppTheme.padding)
                }
                .refreshable {
                    await onRefresh()
                }
            }

            if isUnreachable && !isLoading {
                OfflineBanner(serviceName: serviceType.displayName) {
                    Task { await servicesStore.checkReachability(for: serviceType) }
                }
            }
        }
    }

    // MARK: - Loading

    @ViewBuilder
    private var loadingView: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.gridSpacing) {
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: AppTheme.gridSpacing
                ) {
                    ForEach(0..<4) { _ in SkeletonStatCard() }
                }
                ForEach(0..<3) { _ in SkeletonRow() }
            }
            .padding(AppTheme.padding)
        }
    }

    // MARK: - Error

    @ViewBuilder
    private func errorView(_ error: Error) -> some View {
        ContentUnavailableView(
            label: {
                Label("Error", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(AppTheme.danger)
            },
            description: {
                Text(error.localizedDescription)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            },
            actions: {
                Button("Retry") { Task { await onRefresh() } }
                    .buttonStyle(.glassProminent)
            }
        )
    }
}

// MARK: - Two-column grid helper

let twoColumnGrid = [GridItem(.flexible()), GridItem(.flexible())]
