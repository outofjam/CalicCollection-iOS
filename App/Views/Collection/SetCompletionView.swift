//
//  SetCompletionView.swift
//  LottaPaws
//

import SwiftUI
import SwiftData

struct SetCompletionView: View {
    let ownedVariants: [OwnedVariant]
    
    @State private var sets: [SetBrowseResponse] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showIncompleteOnly = false
    
    private var setCompletions: [SetCompletion] {
        let ownedUuids = Set(ownedVariants.map { $0.variantUuid })
        
        let all = sets.map { set in
            let ownedCount = set.variants.filter { ownedUuids.contains($0.uuid) }.count
            return SetCompletion(
                set: set,
                ownedCount: ownedCount,
                ownedVariantUuids: Set(set.variants.filter { ownedUuids.contains($0.uuid) }.map { $0.uuid })
            )
        }
        .filter { $0.ownedCount > 0 }
        .sorted { $0.percentage > $1.percentage }
        
        if showIncompleteOnly {
            return all.filter { !$0.isComplete }
        }
        return all
    }
    
    private var overallStats: (started: Int, complete: Int, totalOwned: Int, totalInSets: Int) {
        let started = setCompletions.count
        let complete = setCompletions.filter { $0.isComplete }.count
        let totalOwned = setCompletions.reduce(0) { $0 + $1.ownedCount }
        let totalInSets = setCompletions.reduce(0) { $0 + $1.totalCount }
        return (started, complete, totalOwned, totalInSets)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: LottaPawsTheme.spacingXL) {
                if isLoading {
                    ProgressView("Loading sets...")
                        .padding(.top, 100)
                } else if let error = errorMessage {
                    errorView(error)
                } else if setCompletions.isEmpty {
                    emptyView
                } else {
                    statsContent
                }
            }
            .padding(LottaPawsTheme.spacingLG)
        }
        .background(Color.backgroundPrimary)
        .navigationTitle("Set Completion")
        .task {
            await loadSets()
        }
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: LottaPawsTheme.spacingMD) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.warningYellow)
            Text(error)
                .foregroundColor(.textSecondary)
            Button("Retry") {
                Task { await loadSets() }
            }
            .buttonStyle(.bordered)
        }
        .padding(.top, 100)
    }
    
    private var emptyView: some View {
        VStack(spacing: LottaPawsTheme.spacingMD) {
            Image(systemName: "square.stack.3d.up")
                .font(.largeTitle)
                .foregroundColor(.textTertiary)
            Text("No sets started yet")
                .foregroundColor(.textSecondary)
            Text("Add variants to your collection to track set completion")
                .font(.caption)
                .foregroundColor(.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 100)
    }
    
    private var statsContent: some View {
        VStack(spacing: LottaPawsTheme.spacingXL) {
            let stats = overallStats
            
            VStack(spacing: LottaPawsTheme.spacingSM) {
                Text("\(stats.complete)")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundStyle(LinearGradient.lottaGradient)
                
                Text("Sets Complete")
                    .font(.title3)
                    .foregroundColor(.textSecondary)
                
                Text("\(stats.started) sets started - \(stats.totalOwned) of \(stats.totalInSets) variants")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }
            .padding(.top, LottaPawsTheme.spacingLG)
            
            if stats.totalInSets > 0 {
                let percentage = Double(stats.totalOwned) / Double(stats.totalInSets)
                VStack(spacing: LottaPawsTheme.spacingSM) {
                    HStack {
                        Text("Set Completion")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                        Spacer()
                        Text("\(stats.totalOwned) of \(stats.totalInSets)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)
                    }
                    
                    LPProgressBar(progress: percentage, color: .primaryPink, height: 12)
                    
                    Text("\(Int(percentage * 100))% complete across \(stats.started) sets")
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                }
                .padding(LottaPawsTheme.spacingLG)
                .background(
                    RoundedRectangle(cornerRadius: LottaPawsTheme.radiusMD)
                        .fill(Color.primaryPinkLight.opacity(0.3))
                )
            }
            
            Toggle("Show incomplete only", isOn: $showIncompleteOnly)
                .padding(.horizontal, LottaPawsTheme.spacingXS)
                .tint(.primaryPink)
            
            LPDivider()
            
            VStack(alignment: .leading, spacing: LottaPawsTheme.spacingLG) {
                Text("By Set")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                ForEach(setCompletions) { completion in
                    SetStatRow(completion: completion)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func loadSets() async {
        isLoading = true
        errorMessage = nil
        
        do {
            sets = try await BrowseService.shared.fetchSets()
            isLoading = false
        } catch {
            AppLogger.error("Failed to load sets: \(error)")
            errorMessage = "Couldn't load sets. Check your connection."
            isLoading = false
        }
    }
}

// MARK: - Set Completion Model

struct SetCompletion: Identifiable {
    let set: SetBrowseResponse
    let ownedCount: Int
    let ownedVariantUuids: Set<String>
    
    var id: String { return set.uuid }
    var totalCount: Int { return set.variantCount }
    
    var percentage: Double {
        totalCount > 0 ? Double(ownedCount) / Double(totalCount) : 0
    }
    
    var isComplete: Bool {
        ownedCount >= totalCount
    }
}

// MARK: - Set Stat Row

private struct SetStatRow: View {
    let completion: SetCompletion
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: LottaPawsTheme.spacingSM) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(completion.set.name)
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                            
                            if let epochId = completion.set.epochId {
                                Text("·")
                                    .font(.subheadline)
                                    .foregroundColor(.textTertiary)
                                Text(epochId)
                                    .font(.subheadline)
                                    .foregroundColor(.textTertiary)
                            }
                        }
                        
                        if let year = completion.set.releaseYear {
                            Text("Released \(String(year))")
                                .font(.caption)
                                .foregroundColor(.textTertiary)
                        }
                    }
                    
                    Spacer()
                    
                    Text("\(completion.ownedCount) of \(completion.totalCount)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(completion.isComplete ? .successGreen : .textPrimary)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)
            
            LPProgressBar(
                progress: completion.percentage,
                color: completion.isComplete ? .successGreen : .primaryPink,
                height: 8
            )
            
            Text("\(Int(completion.percentage * 100))% complete")
                .font(.caption)
                .foregroundColor(completion.isComplete ? .successGreen : .textTertiary)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: LottaPawsTheme.spacingSM) {
                    ForEach(completion.set.variants) { variant in
                        SetVariantRow(
                            variant: variant,
                            isOwned: completion.ownedVariantUuids.contains(variant.uuid)
                        )
                    }
                }
                .padding(.top, LottaPawsTheme.spacingSM)
            }
        }
        .padding(LottaPawsTheme.spacingMD)
        .background(
            RoundedRectangle(cornerRadius: LottaPawsTheme.radiusMD)
                .fill(Color.backgroundSecondary)
        )
    }
}

// MARK: - Set Variant Row

private struct SetVariantRow: View {
    let variant: SetVariantInfo
    let isOwned: Bool
    
    var body: some View {
        HStack(spacing: LottaPawsTheme.spacingMD) {
            thumbnailView
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: LottaPawsTheme.radiusSM))
                .opacity(isOwned ? 1.0 : 0.4)
            
            Text(variant.name)
                .font(.subheadline)
                .foregroundColor(isOwned ? .textPrimary : .textTertiary)
                .strikethrough(!isOwned, color: .textTertiary)
            
            Spacer()
            
            if isOwned {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.successGreen)
                    .font(.subheadline)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.textTertiary)
                    .font(.subheadline)
            }
        }
    }
    
    @ViewBuilder
    private var thumbnailView: some View {
        if let urlString = variant.thumbnailUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    placeholderRect
                }
            }
        } else {
            placeholderRect
        }
    }
    
    private var placeholderRect: some View {
        RoundedRectangle(cornerRadius: LottaPawsTheme.radiusSM)
            .fill(Color.backgroundTertiary)
            .overlay {
                Image(systemName: "photo")
                    .font(.caption2)
                    .foregroundColor(.textTertiary)
            }
    }
}

#Preview {
    NavigationStack {
        SetCompletionView(ownedVariants: [])
    }
}
