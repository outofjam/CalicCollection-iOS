//
//  SettingsView.swift
//  LottaPaws
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var syncService: SyncService
    @ObservedObject private var appSettings = AppSettings.shared
    
    @State private var showingSyncConfirmation = false
    @State private var refreshID = UUID()
    @State private var apiStats: APIStats?
    @State private var isLoadingStats = false
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Preferences
                Section {
                    Toggle(isOn: $appSettings.showPurchaseDetails) {
                        VStack(alignment: .leading, spacing: LottaPawsTheme.spacingXS) {
                            Text("Show Purchase Details")
                                .font(.body)
                                .foregroundColor(.textPrimary)
                            Text("Track price, date, location, and condition")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    .tint(.primaryPink)
                    
                    Toggle(isOn: $appSettings.showConfetti) {
                        VStack(alignment: .leading, spacing: LottaPawsTheme.spacingXS) {
                            Text("Celebration Effects")
                                .font(.body)
                                .foregroundColor(.textPrimary)
                            Text("Show confetti when adding to collection")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    .tint(.primaryPink)
                    
                    Picker(selection: $appSettings.collectionBadgeStyle) {
                        ForEach(CollectionBadgeStyle.allCases, id: \.self) { style in
                            Text(style.displayName).tag(style)
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: LottaPawsTheme.spacingXS) {
                            Text("Collection Badge")
                                .font(.body)
                                .foregroundColor(.textPrimary)
                            Text("Show count on Collection tab")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    .tint(.primaryPink)
                } header: {
                    Text("Preferences")
                } footer: {
                    Text("Purchase details are optional collector features. Turn off to simplify the interface for younger users.")
                }
                
                // MARK: - Data
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: LottaPawsTheme.spacingXS) {
                            Text("Last Synced")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                            
                            if let lastSync = syncService.lastSyncDate {
                                Text(syncService.timeSinceLastSync)
                                    .font(.body)
                                    .foregroundColor(.textPrimary)
                                    .id(refreshID)
                                
                                Text(lastSync.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.textTertiary)
                            } else {
                                Text("Never")
                                    .font(.body)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        
                        Spacer()
                        
                        if syncService.isSyncing {
                            ProgressView()
                                .tint(.primaryPink)
                        }
                    }
                    
                    Button {
                        showingSyncConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Force Sync Now")
                        }
                        .foregroundColor(.primaryPink)
                    }
                    .disabled(syncService.isSyncing)
                    
                    if let error = syncService.syncError {
                        HStack(alignment: .top, spacing: LottaPawsTheme.spacingSM) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.errorRed)
                            
                            VStack(alignment: .leading, spacing: LottaPawsTheme.spacingXS) {
                                Text("Sync Error")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.textPrimary)
                                
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                    
                    NavigationLink {
                        DataManagementView()
                    } label: {
                        Label("Data Management", systemImage: "externaldrive")
                            .foregroundColor(.textPrimary)
                    }
                } header: {
                    Text("Data")
                } footer: {
                    if syncService.needsSync {
                        Text("It's been a while since your last sync. Consider syncing to get the latest families.")
                    }
                }
                
                // MARK: - About & Support
                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About", systemImage: "info.circle")
                            .foregroundColor(.textPrimary)
                    }
                    
                    Button {
                        UIApplication.shared.open(Config.buyMeCoffeeURL)
                    } label: {
                        HStack(spacing: LottaPawsTheme.spacingSM) {
                            ZStack {
                                Image(systemName: "cup.and.saucer.fill")
                                    .font(.title2)
                                    .foregroundColor(.brown)
                                
                                Image(systemName: "pawprint.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(.primaryPink)
                                    .offset(x: 10, y: -10)
                            }
                            .frame(width: 32)
                            
                            VStack(alignment: .leading, spacing: LottaPawsTheme.spacingXS) {
                                Text("Support LottaPaws")
                                    .font(.body)
                                    .foregroundColor(.textPrimary)
                                
                                Text("Fuel the developer 🐾☕")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.textTertiary)
                        }
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                refreshID = UUID()
                Task {
                    await loadStats()
                }
            }
            .alert("Force Sync?", isPresented: $showingSyncConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Sync Now") {
                    Task {
                        await syncService.syncFamilies(modelContext: modelContext, force: true)
                    }
                }
            } message: {
                Text("This will refresh family data from the server.")
            }
        }
        .tint(.primaryPink)
    }
    
    private func loadStats() async {
        isLoadingStats = true
        
        do {
            let stats = try await StatsService.shared.fetchStats()
            apiStats = stats
        } catch {
            AppLogger.error("Failed to load stats: \(error)")
            apiStats = nil
        }
        
        isLoadingStats = false
    }
}

struct SettingsIcon: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .frame(width: 22, alignment: .center)
            .foregroundColor(.textSecondary)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environmentObject(SyncService.shared)
    .modelContainer(for: OwnedVariant.self, inMemory: true)
}
