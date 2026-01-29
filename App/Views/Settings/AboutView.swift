//
//  AboutView.swift
//  LottaPaws
//

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
                            .tint(.primaryPink)
                        Spacer()
                    }
                } else if let stats = viewModel.apiStats {
                    HStack {
                        Label("Critters", systemImage: "pawprint.fill")
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Text("\(stats.crittersCount)")
                            .foregroundColor(.textSecondary)
                    }

                    HStack {
                        Label("Variants", systemImage: "photo.stack")
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Text("\(stats.variantsCount)")
                            .foregroundColor(.textSecondary)
                    }

                    HStack {
                        Label("Sets", systemImage: "shippingbox")
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Text("\(stats.setsCount)")
                            .foregroundColor(.textSecondary)
                    }
                } else {
                    HStack {
                        Text("Unable to load stats")
                            .foregroundColor(.textSecondary)
                        Spacer()
                        Button("Retry") {
                            Task { await viewModel.loadStats() }
                        }
                        .font(.subheadline)
                        .foregroundColor(.primaryPink)
                    }
                }
            } header: {
                Text("Database Stats")
            } footer: {
                Text("Total critters, variants, and sets available in the LottaPaws database")
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
                .foregroundColor(.textPrimary)
            Spacer()
            Text(Config.appVersion)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.textSecondary)
        }
    }

    var appNameRow: some View {
        HStack {
            Label("App Name", systemImage: "app.fill")
                .foregroundColor(.textPrimary)
            Spacer()
            Text(Config.appName)
                .foregroundColor(.textSecondary)
        }
    }

    var lastBackupRow: some View {
        HStack {
            Label("Last Backup", systemImage: "clock.arrow.circlepath")
                .foregroundColor(.textPrimary)
            Spacer()
            Text(BackupManager.shared.lastBackupFormatted)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.textSecondary)
        }
    }

    #if DEBUG
    var environmentRow: some View {
        HStack {
            Label("Environment", systemImage: "ladybug.fill")
                .foregroundColor(.textPrimary)
            Spacer()
            Text("Development")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.warningYellow)
        }
    }

    var apiEndpointRow: some View {
        HStack {
            Label("API Endpoint", systemImage: "network")
                .foregroundColor(.textPrimary)
            Spacer()
            Text(
                Config.apiBaseURL
                    .split(separator: "/")
                    .last
                    .map(String.init) ?? ""
            )
            .font(.system(.body, design: .monospaced))
            .foregroundColor(.textSecondary)
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
            AppLogger.error("Failed to load stats: \(error)")
            apiStats = nil
            ToastManager.shared.show("Couldn't load database stats", type: .error)
        }
        isLoadingStats = false
    }
}
