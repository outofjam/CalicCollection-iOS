import SwiftUI
import SwiftData

struct VariantPickerSheet: View {
    let critter: Critter
    let targetStatus: CritterStatus
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query private var allVariants: [CritterVariant]
    @Query private var ownedVariants: [OwnedVariant]
    
    @State private var selectedVariantIds: Set<String> = []
    
    private var critterVariants: [CritterVariant] {
        allVariants
            .filter { $0.critterId == critter.uuid }
            .sorted { ($0.isPrimary ?? false) && !($1.isPrimary ?? false) }
    }
    
    private func isVariantOwned(_ variantUuid: String, status: CritterStatus) -> Bool {
        ownedVariants.contains { $0.variantUuid == variantUuid && $0.status == status }
    }
    
    private var hasOwnedVariants: Bool {
        critterVariants.contains { variant in
            isVariantOwned(variant.uuid, status: targetStatus)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text(critter.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Select variants to add to \(targetStatus == .collection ? "Collection" : "Wishlist")")
                        .font(.subheadline)
                        .foregroundColor(.calicoTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                // Variants list
                if critterVariants.isEmpty {
                    ContentUnavailableView(
                        "No Variants Available",
                        systemImage: "photo.stack",
                        description: Text("This critter has no variants yet")
                    )
                } else {
                    List {
                        ForEach(critterVariants) { variant in
                            VariantRow(
                                variant: variant,
                                isSelected: selectedVariantIds.contains(variant.uuid),
                                isOwned: isVariantOwned(variant.uuid, status: targetStatus)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                toggleVariant(variant.uuid)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    // Only show button if there are selections OR owned variants to remove
                    if !selectedVariantIds.isEmpty || hasOwnedVariants {
                        Button {
                            saveSelection()
                        } label: {
                            HStack {
                                Image(systemName: targetStatus == .collection ? "star.fill" : "heart.fill")
                                if selectedVariantIds.isEmpty {
                                    Text("Remove All from \(targetStatus == .collection ? "Collection" : "Wishlist")")
                                } else {
                                    Text("Add to \(targetStatus == .collection ? "Collection" : "Wishlist") (\(selectedVariantIds.count))")
                                }
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedVariantIds.isEmpty ? Color.red : (targetStatus == .collection ? Color.blue : Color.pink))
                            .cornerRadius(12)
                        }
                    }
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.calicoTextSecondary)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            loadPreselectedVariants()
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadPreselectedVariants() {
        // Pre-select already owned variants
        selectedVariantIds = Set(
            critterVariants
                .filter { isVariantOwned($0.uuid, status: targetStatus) }
                .map { $0.uuid }
        )
    }
    
    private func toggleVariant(_ uuid: String) {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        
        if selectedVariantIds.contains(uuid) {
            selectedVariantIds.remove(uuid)
        } else {
            selectedVariantIds.insert(uuid)
        }
    }
    
    private func saveSelection() {
        var movedCount = 0
        var addedCount = 0
        var removedCount = 0
        
        // Add/update selected variants
        for variantUuid in selectedVariantIds {
            guard let variant = critterVariants.first(where: { $0.uuid == variantUuid }) else { continue }
            
            // Check if exists in opposite status
            let existsInOpposite = ownedVariants.contains {
                $0.variantUuid == variantUuid && $0.status?.rawValue != targetStatus.rawValue
            }
            
            if existsInOpposite {
                movedCount += 1
            } else if !isVariantOwned(variantUuid, status: targetStatus) {
                addedCount += 1
            }
            
            try? OwnedVariant.create(
                variant: variant,
                critter: critter,
                status: targetStatus,
                in: modelContext
            )
        }
        
        // Remove deselected variants
        let previouslyOwned = critterVariants
            .filter { isVariantOwned($0.uuid, status: targetStatus) }
            .map { $0.uuid }
        
        for variantUuid in previouslyOwned {
            if !selectedVariantIds.contains(variantUuid) {
                try? OwnedVariant.remove(variantUuid: variantUuid, in: modelContext)
                removedCount += 1
            }
        }
        
        // Show appropriate toast
        let statusName = targetStatus == .collection ? "Collection" : "Wishlist"
        
        if movedCount > 0 {
            ToastManager.shared.show("✓ Moved \(movedCount) to \(statusName)", type: .success)
        } else if addedCount > 0 {
            ToastManager.shared.show("✓ Added \(addedCount) to \(statusName)", type: .success)
        } else if removedCount > 0 {
            ToastManager.shared.show("Removed \(removedCount) from \(statusName)", type: .info)
        }
        
        dismiss()
    }
}

// MARK: - Variant Row
struct VariantRow: View {
    let variant: CritterVariant
    let isSelected: Bool
    let isOwned: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .blue : .gray)
                .font(.title3)
            
            // Variant image (use thumbnail for list performance)
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay {
                    // Use thumbnail if available, fallback to full image
                    if let urlString = variant.thumbnailURL ?? variant.imageURL {
                        CachedAsyncImage(url: urlString) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } placeholder: {
                            ProgressView()
                        }
                    } else {
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    }
                }
            
            // Variant info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(variant.name)
                        .font(.headline)
                    
                    if isOwned {
                        Text("✓ Owned")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.calicoSuccess)
                            .cornerRadius(4)
                    }
                }
                
                if let epochId = variant.epochId, let setName = variant.setName {
                    Text("Set \(epochId) • \(setName)")
                        .font(.caption)
                        .foregroundColor(.calicoTextSecondary)
                } else if let epochId = variant.epochId {
                    Text("Set \(epochId)")
                        .font(.caption)
                        .foregroundColor(.calicoTextSecondary)
                } else if let sku = variant.sku {
                    Text("SKU: \(sku)")
                        .font(.caption)
                        .foregroundColor(.calicoTextSecondary)
                }
                
                if let releaseYear = variant.releaseYear {
                    Text("Released: \(String(releaseYear))")
                        .font(.caption2)
                        .foregroundColor(.calicoTextSecondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    Text("Picker Preview")
        .sheet(isPresented: .constant(true)) {
            VariantPickerSheet(
                critter: Critter(
                    uuid: "1",
                    familyId: "1",
                    name: "Test Critter",
                    memberType: "Parents",
                    variantsCount: 3
                ),
                targetStatus: .collection
            )
            .modelContainer(for: OwnedVariant.self, inMemory: true)
        }
}
