//
//  FamilyDetailView.swift
//  CaliCollectionV2
//
//  Created by Ismail Dawoodjee on 2026-01-24.
//

import SwiftUI
import SwiftData

struct FamilyDetailView: View {
    let familyUuid: String
    let familyName: String
    
    @Environment(\.modelContext) private var modelContext
    @Query private var ownedVariants: [OwnedVariant]
    
    @State private var familyDetail: FamilyDetailResponse?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    @State private var selectedCritterUuid: String?
    @State private var pickerTargetStatus: CritterStatus = .collection
    @State private var showVariantPicker = false
    
    private var totalVariants: Int {
        familyDetail?.critters.reduce(0) { $0 + $1.variantsCount } ?? 0
    }
    
    private var ownedInCollection: Int {
        guard let critters = familyDetail?.critters else { return 0 }
        let critterUuids = Set(critters.map { $0.uuid })
        return ownedVariants.filter {
            critterUuids.contains($0.critterUuid) && $0.status == .collection
        }.count
    }
    
    private var ownedInWishlist: Int {
        guard let critters = familyDetail?.critters else { return 0 }
        let critterUuids = Set(critters.map { $0.uuid })
        return ownedVariants.filter {
            critterUuids.contains($0.critterUuid) && $0.status == .wishlist
        }.count
    }
    
    // Group by member type
    private var groupedByMemberType: [String: [FamilyDetailCritter]] {
        guard let critters = familyDetail?.critters else { return [:] }
        return Dictionary(grouping: critters) { $0.memberType.capitalized }
    }
    
    private var sortedMemberTypes: [String] {
        let order = ["Father", "Mother", "Grandfather", "Grandmother", "Brother", "Sister", "Baby"]
        return groupedByMemberType.keys.sorted { first, second in
            let firstIndex = order.firstIndex(of: first) ?? order.count
            let secondIndex = order.firstIndex(of: second) ?? order.count
            return firstIndex < secondIndex
        }
    }
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading family...")
            } else if let error = errorMessage {
                ContentUnavailableView {
                    Label("Error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    Button("Retry") {
                        Task { await loadFamily() }
                    }
                }
            } else if let detail = familyDetail {
                familyContent(detail)
            }
        }
        .navigationTitle(familyName)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadFamily()
        }
        .sheet(isPresented: $showVariantPicker) {
            if let critterUuid = selectedCritterUuid {
                VariantPickerSheet(
                    critterUuid: critterUuid,
                    targetStatus: pickerTargetStatus
                )
            }
        }
    }
    
    @ViewBuilder
    private func familyContent(_ detail: FamilyDetailResponse) -> some View {
        List {
            // Stats section
            Section {
                HStack {
                    StatBadge(
                        icon: "figure.2",
                        label: "Characters",
                        value: "\(detail.critters.count)",
                        color: .blue
                    )
                    
                    Spacer()
                    
                    StatBadge(
                        icon: "photo.stack",
                        label: "Total Variants",
                        value: "\(totalVariants)",
                        color: .purple
                    )
                }
                
                HStack {
                    StatBadge(
                        icon: "star.fill",
                        label: "In Collection",
                        value: "\(ownedInCollection)",
                        color: .blue
                    )
                    
                    Spacer()
                    
                    StatBadge(
                        icon: "heart.fill",
                        label: "In Wishlist",
                        value: "\(ownedInWishlist)",
                        color: .pink
                    )
                }
            }
            .listRowBackground(Color.clear)
            
            // Critters grouped by member type
            ForEach(sortedMemberTypes, id: \.self) { memberType in
                Section {
                    if let critters = groupedByMemberType[memberType] {
                        ForEach(critters.sorted(by: { $0.name < $1.name })) { critter in
                            CritterRowOnline(
                                critter: critter,
                                ownedCount: ownedCountFor(critter)
                            )
                            .swipeActions(edge: .leading) {
                                Button {
                                    handleCollectionAction(for: critter)
                                } label: {
                                    Label("Collection", systemImage: "star.fill")
                                }
                                .tint(.calicoPrimary)
                            }
                            .swipeActions(edge: .trailing) {
                                Button {
                                    handleWishlistAction(for: critter)
                                } label: {
                                    Label("Wishlist", systemImage: "heart.fill")
                                }
                                .tint(.calicoSecondary)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text(memberType)
                        Spacer()
                        if let critters = groupedByMemberType[memberType] {
                            Text("\(critters.count)")
                                .font(.caption)
                                .foregroundColor(.calicoTextSecondary)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadFamily() async {
        isLoading = true
        errorMessage = nil
        
        do {
            familyDetail = try await BrowseService.shared.fetchFamily(uuid: familyUuid)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Helper Methods
    
    private func ownedCountFor(_ critter: FamilyDetailCritter) -> Int {
        ownedVariants.filter { $0.critterUuid == critter.uuid }.count
    }
    
    private func handleCollectionAction(for critter: FamilyDetailCritter) {
        if critter.variantsCount == 0 {
            ToastManager.shared.show("This critter has no variants", type: .error)
            return
        }
        
        pickerTargetStatus = .collection
        selectedCritterUuid = critter.uuid
        showVariantPicker = true
    }
    
    private func handleWishlistAction(for critter: FamilyDetailCritter) {
        if critter.variantsCount == 0 {
            ToastManager.shared.show("This critter has no variants", type: .error)
            return
        }
        
        pickerTargetStatus = .wishlist
        selectedCritterUuid = critter.uuid
        showVariantPicker = true
    }
}

// MARK: - Critter Row (Online Version)
private struct CritterRowOnline: View {
    let critter: FamilyDetailCritter
    let ownedCount: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let urlString = critter.thumbnailUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        placeholderView
                    }
                }
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                placeholderView
                    .frame(width: 50, height: 50)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(critter.name)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Text("\(critter.variantsCount) variant\(critter.variantsCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.calicoTextSecondary)
                    
                    if ownedCount > 0 {
                        Text("• \(ownedCount) owned")
                            .font(.caption)
                            .foregroundColor(.calicoPrimary)
                    }
                }
            }
            
            Spacer()
            
            // Owned indicator
            if ownedCount > 0 {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.calicoPrimary)
            }
        }
        .contentShape(Rectangle())
    }
    
    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.2))
            .overlay {
                Image(systemName: "person.fill")
                    .foregroundColor(.gray)
            }
    }
}

// MARK: - Stat Badge
struct StatBadge: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.calicoTextSecondary)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        FamilyDetailView(familyUuid: "test-uuid", familyName: "Chocolate Rabbit")
    }
}
