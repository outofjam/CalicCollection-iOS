import SwiftUI
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
        allVariants.filter { $0.critterId == critter.uuid }
    }
    
    private func isVariantOwned(_ variantUuid: String, status: CritterStatus) -> Bool {
        ownedVariants.contains { $0.variantUuid == variantUuid && $0.status == status }
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
                        .foregroundColor(.secondary)
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
                    Button {
                        saveSelection()
                    } label: {
                        HStack {
                            Image(systemName: targetStatus == .collection ? "star.fill" : "heart.fill")
                            Text("Add Selected (\(selectedVariantIds.count))")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedVariantIds.isEmpty ? Color.gray : (targetStatus == .collection ? Color.blue : Color.pink))
                        .cornerRadius(12)
                    }
                    .disabled(selectedVariantIds.isEmpty)
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
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
        if selectedVariantIds.contains(uuid) {
            selectedVariantIds.remove(uuid)
        } else {
            selectedVariantIds.insert(uuid)
        }
    }
    
    private func saveSelection() {
        // Add selected variants
        for variantUuid in selectedVariantIds {
            guard let variant = critterVariants.first(where: { $0.uuid == variantUuid }) else { continue }
            
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
            }
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
            
            // Variant image placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay {
                    if let imageURL = variant.imageURL {
                        AsyncImage(url: URL(string: imageURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
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
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                }
                
                if let sku = variant.sku {
                    Text("SKU: \(sku)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let releaseYear = variant.releaseYear {
                    Text("Released: \(String(releaseYear))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
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
