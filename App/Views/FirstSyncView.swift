//
//  FirstSyncView.swift
//  LottaPaws
//

import SwiftUI
import SwiftData

struct FirstSyncView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var syncService: SyncService
    @ObservedObject private var appSettings = AppSettings.shared
    
    @State private var syncProgress: Double = 0.0
    @State private var syncComplete = false
    @State private var showBirthdayStep = false
    
    // Birthday picker state
    @State private var selectedMonth = 1
    @State private var selectedDay = 1
    
    private let months = [
        (1, "January"), (2, "February"), (3, "March"), (4, "April"),
        (5, "May"), (6, "June"), (7, "July"), (8, "August"),
        (9, "September"), (10, "October"), (11, "November"), (12, "December")
    ]
    
    private var daysInMonth: Int {
        switch selectedMonth {
        case 2: return 29 // Allow 29 for leap years
        case 4, 6, 9, 11: return 30
        default: return 31
        }
    }
    
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
            
            // Content based on state
            if showBirthdayStep {
                birthdayContent
            } else {
                syncContent
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
    
    // MARK: - Sync Content
    
    private var syncContent: some View {
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
    }
    
    // MARK: - Birthday Content
    
    private var birthdayContent: some View {
        VStack(spacing: LottaPawsTheme.spacingLG) {
            VStack(spacing: LottaPawsTheme.spacingSM) {
                Image(systemName: "birthday.cake.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.primaryPink)
                
                Text("When's your birthday?")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                Text("Find critters who share your special day! 🎂")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Month and Day pickers
            HStack(spacing: LottaPawsTheme.spacingMD) {
                // Month picker
                Picker("Month", selection: $selectedMonth) {
                    ForEach(months, id: \.0) { month in
                        Text(month.1).tag(month.0)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 140, height: 120)
                .clipped()
                
                // Day picker
                Picker("Day", selection: $selectedDay) {
                    ForEach(1...daysInMonth, id: \.self) { day in
                        Text("\(day)").tag(day)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 80, height: 120)
                .clipped()
            }
            .onChange(of: selectedMonth) { _, _ in
                // Adjust day if it exceeds new month's days
                if selectedDay > daysInMonth {
                    selectedDay = daysInMonth
                }
            }
            
            // Action buttons
            VStack(spacing: LottaPawsTheme.spacingMD) {
                Button("Save Birthday") {
                    saveBirthdayAndFinish()
                }
                .buttonStyle(.primary)
                
                Button("Skip for now") {
                    finishOnboarding()
                }
                .font(.subheadline)
                .foregroundColor(.textSecondary)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .trailing)))
    }
    
    // MARK: - Actions
    
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
            
            // Wait another moment before showing birthday step
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showBirthdayStep = true
            }
        }
    }
    
    private func saveBirthdayAndFinish() {
        let birthday = AppSettings.formatBirthdayForStorage(month: selectedMonth, day: selectedDay)
        appSettings.userBirthday = birthday
        finishOnboarding()
    }
    
    private func finishOnboarding() {
        // Mark first launch as complete
        UserDefaults.standard.set(true, forKey: Config.UserDefaultsKeys.hasCompletedFirstSync)
    }
}

#Preview {
    FirstSyncView()
        .environmentObject(SyncService.shared)
        .modelContainer(for: [OwnedVariant.self, Family.self], inMemory: true)
}
