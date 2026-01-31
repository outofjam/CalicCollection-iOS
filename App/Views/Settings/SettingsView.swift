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
    @State private var showingBirthdayPicker = false
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
                    
                    // Birthday row
                    Button {
                        showingBirthdayPicker = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: LottaPawsTheme.spacingXS) {
                                Text("Your Birthday")
                                    .font(.body)
                                    .foregroundColor(.textPrimary)
                                Text("Find critters who share your birthday")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                            
                            Spacer()
                            
                            if let display = appSettings.userBirthdayDisplay {
                                Text(display)
                                    .font(.subheadline)
                                    .foregroundColor(.primaryPink)
                            } else {
                                Text("Not set")
                                    .font(.subheadline)
                                    .foregroundColor(.textTertiary)
                            }
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.textTertiary)
                        }
                    }
                    .buttonStyle(.plain)
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
            .sheet(isPresented: $showingBirthdayPicker) {
                BirthdayPickerSheet()
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

// MARK: - Birthday Picker Sheet

struct BirthdayPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var appSettings = AppSettings.shared
    
    @State private var selectedMonth: Int
    @State private var selectedDay: Int
    
    private let months = [
        (1, "January"), (2, "February"), (3, "March"), (4, "April"),
        (5, "May"), (6, "June"), (7, "July"), (8, "August"),
        (9, "September"), (10, "October"), (11, "November"), (12, "December")
    ]
    
    private var daysInMonth: Int {
        switch selectedMonth {
        case 2: return 29
        case 4, 6, 9, 11: return 30
        default: return 31
        }
    }
    
    init() {
        // Initialize with current birthday or defaults
        if let birthday = AppSettings.shared.userBirthday {
            let parts = birthday.split(separator: "-")
            if parts.count == 2,
               let month = Int(parts[0]),
               let day = Int(parts[1]) {
                _selectedMonth = State(initialValue: month)
                _selectedDay = State(initialValue: day)
            } else {
                _selectedMonth = State(initialValue: 1)
                _selectedDay = State(initialValue: 1)
            }
        } else {
            _selectedMonth = State(initialValue: 1)
            _selectedDay = State(initialValue: 1)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: LottaPawsTheme.spacingXL) {
                VStack(spacing: LottaPawsTheme.spacingSM) {
                    Image(systemName: "birthday.cake.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.primaryPink)
                    
                    Text("Your Birthday")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                    Text("Find critters who share your special day! 🎂")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, LottaPawsTheme.spacingXL)
                
                // Month and Day pickers
                HStack(spacing: LottaPawsTheme.spacingMD) {
                    Picker("Month", selection: $selectedMonth) {
                        ForEach(months, id: \.0) { month in
                            Text(month.1).tag(month.0)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 150, height: 150)
                    .clipped()
                    
                    Picker("Day", selection: $selectedDay) {
                        ForEach(1...daysInMonth, id: \.self) { day in
                            Text("\(day)").tag(day)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80, height: 150)
                    .clipped()
                }
                .onChange(of: selectedMonth) { _, _ in
                    if selectedDay > daysInMonth {
                        selectedDay = daysInMonth
                    }
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: LottaPawsTheme.spacingMD) {
                    Button("Save Birthday") {
                        saveBirthday()
                    }
                    .buttonStyle(.primary)
                    
                    if appSettings.userBirthday != nil {
                        Button("Remove Birthday") {
                            appSettings.userBirthday = nil
                            dismiss()
                        }
                        .font(.subheadline)
                        .foregroundColor(.errorRed)
                    }
                }
                .padding(.bottom, LottaPawsTheme.spacingLG)
            }
            .padding(LottaPawsTheme.spacingLG)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.textSecondary)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    private func saveBirthday() {
        let birthday = AppSettings.formatBirthdayForStorage(month: selectedMonth, day: selectedDay)
        appSettings.userBirthday = birthday
        dismiss()
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
