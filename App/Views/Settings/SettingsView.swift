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
                // MARK: - Sync Section
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Last Synced")
                                .font(.subheadline)
                                .foregroundColor(.calicoTextSecondary)
                            
                            if let lastSync = syncService.lastSyncDate {
                                Text(syncService.timeSinceLastSync)
                                    .font(.body)
                                    .id(refreshID)
                                
                                Text(lastSync.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.calicoTextSecondary)
                            } else {
                                Text("Never")
                                    .font(.body)
                                    .foregroundColor(.calicoTextSecondary)
                            }
                        }
                        
                        Spacer()
                        
                        if syncService.isSyncing {
                            ProgressView()
                        }
                    }
                    
                    Button {
                        showingSyncConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Force Sync Now")
                        }
                    }
                    .disabled(syncService.isSyncing)
                    
                    if let error = syncService.syncError {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.calicoError)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Sync Error")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.calicoTextSecondary)
                            }
                        }
                    }
                } header: {
                    Text("Sync")
                } footer: {
                    if syncService.needsSync {
                        Text("It's been a while since your last sync. Consider syncing to get the latest critters.")
                    }
                }
                
                // MARK: - Preferences Section
                Section {
                    Toggle(isOn: $appSettings.showPurchaseDetails) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Show Purchase Details")
                                .font(.body)
                            Text("Track price, date, location, and condition")
                                .font(.caption)
                                .foregroundColor(.calicoTextSecondary)
                        }
                    }
                } header: {
                    Text("Preferences")
                } footer: {
                    Text("Purchase details are optional collector features. Turn off to simplify the interface for younger users.")
                }
                
                // MARK: - About
                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About", systemImage: "info.circle")
                    }
                }
                
                // MARK: - Data Section
                Section {
                    NavigationLink {
                        DataManagementView()
                    } label: {
                        Label("Data Management", systemImage: "externaldrive")
                    }
                } header: {
                    Text("Data")
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
                        await syncService.syncAll(modelContext: modelContext, force: true)
                    }
                }
            } message: {
                Text("This will refresh all critters and variants from the server.")
            }
        }
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
            .foregroundStyle(.secondary)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environmentObject(SyncService.shared)
    .modelContainer(for: OwnedVariant.self, inMemory: true)
}
