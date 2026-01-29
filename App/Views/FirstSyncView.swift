//
//  FirstSyncView.swift
//  LottaPaws
//

import SwiftUI
import SwiftData

struct FirstSyncView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var syncService: SyncService
    
    @State private var syncProgress: Double = 0.0
    @State private var syncComplete = false
    
    var body: some View {
        VStack(spacing: LottaPawsTheme.spacingXXL) {
            Spacer()
            
            // App Icon / Logo
            Image("LaunchIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: LottaPawsTheme.radiusXL))
                .shadow(
                    color: LottaPawsTheme.shadowMedium.color,
                    radius: LottaPawsTheme.shadowMedium.radius,
                    x: 0,
                    y: 8
                )
            
            // Welcome Text
            VStack(spacing: LottaPawsTheme.spacingSM) {
                Text("Welcome to")
                    .font(.title2)
                    .foregroundColor(.textSecondary)
                
                Text("LottaPaws")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
            }
            
            // Sync Status
            VStack(spacing: LottaPawsTheme.spacingLG) {
                if syncService.isSyncing {
                    VStack(spacing: LottaPawsTheme.spacingMD) {
                        LPProgressBar(progress: syncProgress, color: .primaryPink)
                            .frame(width: 200)
                        
                        Text("Setting up...")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                } else if let error = syncService.syncError {
                    VStack(spacing: LottaPawsTheme.spacingMD) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.errorRed)
                        
                        Text("Setup Failed")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, LottaPawsTheme.spacingXL)
                        
                        Button("Try Again") {
                            startSync()
                        }
                        .buttonStyle(.primary)
                    }
                } else if syncComplete {
                    VStack(spacing: LottaPawsTheme.spacingMD) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.successGreen)
                        
                        Text("All set!")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                    }
                } else {
                    Button("Get Started") {
                        startSync()
                    }
                    .buttonStyle(.primary)
                }
            }
            
            Spacer()
            
            // App Version
            Text("Version \(Config.appVersion)")
                .font(.caption2)
                .foregroundColor(.textTertiary)
        }
        .padding(LottaPawsTheme.spacingLG)
        .background(
            LinearGradient.lottaGradient
                .opacity(0.15)
                .ignoresSafeArea()
        )
    }
    
    private func startSync() {
        Task {
            // Simulate progress
            syncProgress = 0.0
            
            // Start sync (only families now)
            await syncService.syncFamilies(modelContext: modelContext, force: true)
            
            // Animate progress
            withAnimation(.easeInOut(duration: 1.0)) {
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
        .modelContainer(for: [OwnedVariant.self, Family.self], inMemory: true)
}
