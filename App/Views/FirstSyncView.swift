import SwiftUI
import SwiftData

struct FirstSyncView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var syncService: SyncService
    
    @State private var syncProgress: Double = 0.0
    @State private var syncComplete = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // App Icon / Logo
            Image(systemName: "pawprint.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Welcome Text
            VStack(spacing: 8) {
                Text("Welcome to")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text("CaliCollection")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            
            // Sync Status
            VStack(spacing: 16) {
                if syncService.isSyncing {
                    ProgressView(value: syncProgress)
                        .progressViewStyle(.linear)
                        .frame(width: 200)
                    
                    Text("Syncing critters...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else if let error = syncService.syncError {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                        
                        Text("Sync Failed")
                            .font(.headline)
                        
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button {
                            startSync()
                        } label: {
                            Text("Try Again")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                    }
                } else if syncComplete {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.green)
                        
                        Text("All set!")
                            .font(.headline)
                    }
                } else {
                    Button {
                        startSync()
                    } label: {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
            }
            
            Spacer()
            
            // App Version
            Text("Version \(Config.appVersion)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private func startSync() {
        Task {
            // Simulate progress
            syncProgress = 0.0
            
            // Start sync
            await syncService.syncAll(modelContext: modelContext, force: true)
            
            // Animate progress
            withAnimation(.easeInOut(duration: 1.5)) {
                syncProgress = 1.0
            }
            
            // Wait a moment before marking complete
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            withAnimation {
                syncComplete = true
            }
            
            // Wait another moment before dismissing
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            // Mark first launch as complete
            UserDefaults.standard.set(true, forKey: Config.UserDefaultsKeys.hasCompletedFirstSync)
        }
    }
}

#Preview {
    FirstSyncView()
        .environmentObject(SyncService.shared)
        .modelContainer(for: OwnedVariant.self, inMemory: true)
}
