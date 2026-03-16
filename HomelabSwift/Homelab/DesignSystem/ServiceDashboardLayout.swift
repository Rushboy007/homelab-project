import SwiftUI

// Maps to components/ServiceDashboardLayout.tsx
// Generic wrapper providing: loading state, error state, pull-to-refresh, offline banner.

struct ServiceDashboardLayout<T, Content: View>: View {
    let serviceType: ServiceType
    let instanceId: UUID
    let state: LoadableState<T>
    let onRefresh: () async -> Void
    @ViewBuilder let content: () -> Content

    @Environment(ServicesStore.self) private var servicesStore
    @State private var refreshID = UUID()

    var isUnreachable: Bool {
        servicesStore.reachability(for: instanceId) == false
    }

    private var stateChangeToken: String {
        switch state {
        case .idle:
            return "idle"
        case .loading:
            return "loading"
        case .loaded:
            return "loaded"
        case .error(let apiError):
            return "error:\(apiError.localizedDescription)"
        case .offline:
            return "offline"
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            switch state {
            case .idle, .loading:
                loadingView
            case .error(let apiError):
                ServiceErrorView(error: apiError, retryAction: onRefresh)
            case .offline:
                ServiceErrorView(error: .networkError(NSError(domain: "Network", code: -1009)), retryAction: onRefresh)
            case .loaded:
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

            if isUnreachable && !state.isLoading {
                OfflineBanner(serviceName: serviceType.displayName) {
                    Task { await servicesStore.checkReachability(for: instanceId) }
                }
            }
        }
        .onChange(of: stateChangeToken) { _, _ in
            AppLogger.shared.stateTransition(service: serviceType.displayName, state: state)
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

    // old errorView removed (now using ServiceErrorView directly)
}

// MARK: - Two-column grid helper

let twoColumnGrid = [GridItem(.flexible()), GridItem(.flexible())]
