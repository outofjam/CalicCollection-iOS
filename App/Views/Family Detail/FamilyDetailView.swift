//
//  FamilyDetailView.swift
//  CaliCollectionV2
//
//  Created by Ismail Dawoodjee on 2026-01-24.
//


import SwiftUI
import SwiftData

struct FamilyDetailView: View {
    let familyName: String
    
    @Environment(\.modelContext) private var modelContext
    @Query private var allCritters: [Critter]
    @Query private var allVariants: [CritterVariant]
    @Query private var ownedVariants: [OwnedVariant]
    
    @State private var selectedCritter: Critter?
    @State private var pickerTargetStatus: CritterStatus = .collection
    
    private var familyCritters: [Critter] {
        allCritters.filter { $0.familyName == familyName }
    }
    
    private var totalVariants: Int {
        familyCritters.reduce(0) { $0 + $1.variantsCount }
    }
    
    private var ownedInCollection: Int {
        let critterUuids = Set(familyCritters.map { $0.uuid })
        return ownedVariants.filter { 
            critterUuids.contains($0.critterUuid) && $0.status == .collection 
        }.count
    }
    
    private var ownedInWishlist: Int {
        let critterUuids = Set(familyCritters.map { $0.uuid })
        return ownedVariants.filter { 
            critterUuids.contains($0.critterUuid) && $0.status == .wishlist 
        }.count
    }
    
    // Group by member type
    private var groupedByMemberType: [String: [Critter]] {
        Dictionary(grouping: familyCritters) { $0.memberType }
    }
    
    private var sortedMemberTypes: [String] {
        // Custom sort order: Parents, Grandparents, Kids, Babies, Other
        let order = ["Parents", "Grandparents", "Kids", "Babies", "Other"]
        return groupedByMemberType.keys.sorted { first, second in
            let firstIndex = order.firstIndex(of: first) ?? order.count
            let secondIndex = order.firstIndex(of: second) ?? order.count
            return firstIndex < secondIndex
        }
    }
    
    var body: some View {
        List {
            // Stats section
            Section {
                HStack {
                    StatBadge(
                        icon: "figure.2",
                        label: "Characters",
                        value: "\(familyCritters.count)",
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
                            NavigationLink {
                                CritterDetailView(critter: critter)
                            } label: {
                                CritterRow(
                                    critter: critter,
                                    ownedVariants: ownedVariantsFor(critter)
                                )
                            }
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
        .navigationTitle(familyName)
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedCritter) { critter in
            VariantPickerSheet(
                critter: critter,
                targetStatus: pickerTargetStatus
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func ownedVariantsFor(_ critter: Critter) -> [OwnedVariant] {
        ownedVariants.filter { $0.critterUuid == critter.uuid }
    }
    
    private func handleCollectionAction(for critter: Critter) {
        if critter.variantsCount == 0 {
            ToastManager.shared.show("This critter has no variants", type: .error)
            return
        }
        
        if critter.variantsCount == 1 {
            addSingleVariant(critter: critter, status: .collection)
        } else {
            pickerTargetStatus = .collection
            selectedCritter = critter
        }
    }
    
    private func handleWishlistAction(for critter: Critter) {
        if critter.variantsCount == 0 {
            ToastManager.shared.show("This critter has no variants", type: .error)
            return
        }
        
        if critter.variantsCount == 1 {
            addSingleVariant(critter: critter, status: .wishlist)
        } else {
            pickerTargetStatus = .wishlist
            selectedCritter = critter
        }
    }
    
    private func addSingleVariant(critter: Critter, status: CritterStatus) {
        let critterVariants = allVariants.filter { $0.critterId == critter.uuid }
        
        guard let variant = critterVariants.first else {
            ToastManager.shared.show("Variant not found", type: .error)
            return
        }
        
        let alreadyOwned = ownedVariants.contains {
            $0.variantUuid == variant.uuid && $0.status == status
        }
        
        if alreadyOwned {
            try? OwnedVariant.remove(variantUuid: variant.uuid, in: modelContext)
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            
            ToastManager.shared.show(
                "Removed \(variant.name) from \(status == .collection ? "Collection" : "Wishlist")",
                type: .info
            )
        } else {
            try? OwnedVariant.create(
                variant: variant,
                critter: critter,
                status: status,
                in: modelContext
            )
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            ToastManager.shared.show(
                "✓ Added \(variant.name) to \(status == .collection ? "Collection" : "Wishlist")",
                type: .success
            )
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
        FamilyDetailView(familyName: "Chocolate Rabbit")
            .modelContainer(for: Critter.self, inMemory: true)
    }
}
