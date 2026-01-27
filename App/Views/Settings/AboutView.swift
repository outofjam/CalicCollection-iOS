import SwiftUI
import Combine

// MARK: - AboutView
struct AboutView: View {
    @ObservedObject private var viewModel = AboutViewModel.shared
    
    var body: some View {
        List {
            // MARK: - About Info
            Section {
                versionRow
                appNameRow
                lastBackupRow

                #if DEBUG
                environmentRow
                apiEndpointRow
                #endif
            } header: {
                Text("About")
            }

            // MARK: - Database Stats
            Section {
                if viewModel.isLoadingStats {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if let stats = viewModel.apiStats {
                    HStack {
                        Label("Critters", systemImage: "pawprint.fill")
                        Spacer()
                        Text("\(stats.crittersCount)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Variants", systemImage: "photo.stack")
                        Spacer()
                        Text("\(stats.variantsCount)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Sets", systemImage: "shippingbox")
                        Spacer()
                        Text("\(stats.setsCount)")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    HStack {
                        Text("Unable to load stats")
                            .foregroundColor(.calicoTextSecondary)
                        Spacer()
                        Button("Retry") {
                            Task { await viewModel.loadStats() }
                        }
                        .font(.subheadline)
                    }
                }
            } header: {
                Text("Database Stats")
            } footer: {
                Text("Total critters, variants, and sets available in the CaliCollection database")
            }
        }
        .navigationTitle("About")
        .onAppear {
            Task { await viewModel.loadStats() }
        }
    }
}

// MARK: - About Rows
private extension AboutView {
    var versionRow: some View {
        HStack {
            Label("Version", systemImage: "number")
            Spacer()
            Text(Config.appVersion)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }

    var appNameRow: some View {
        HStack {
            Label("App Name", systemImage: "app.fill")
            Spacer()
            Text(Config.appName)
                .foregroundStyle(.secondary)
        }
    }

    var lastBackupRow: some View {
        HStack {
            Label("Last Backup", systemImage: "clock.arrow.circlepath")
            Spacer()
            Text(BackupManager.shared.lastBackupFormatted)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }

    #if DEBUG
    var environmentRow: some View {
        HStack {
            Label("Environment", systemImage: "ladybug.fill")
            Spacer()
            Text("Development")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.orange)
        }
    }

    var apiEndpointRow: some View {
        HStack {
            Label("API Endpoint", systemImage: "network")
            Spacer()
            Text(
                Config.apiBaseURL
                    .split(separator: "/")
                    .last
                    .map(String.init) ?? ""
            )
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
    }
    #endif
}

// MARK: - AboutViewModel
@MainActor
class AboutViewModel: ObservableObject {
    static let shared = AboutViewModel()
    
    @Published var apiStats: APIStats?
    @Published var isLoadingStats = false
    
    func loadStats() async {
        isLoadingStats = true
        do {
            apiStats = try await StatsService.shared.fetchStats()
        } catch {
            print("Failed to load stats: \(error)")
            apiStats = nil
        }
        isLoadingStats = false
    }
}
