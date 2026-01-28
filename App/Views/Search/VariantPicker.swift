import SwiftUI
import SwiftData

struct VariantPickerSheet: View {
    let critterUuid: String
    let targetStatus: CritterStatus
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query private var ownedVariants: [OwnedVariant]
    
    @State private var critterData: CritterVariantsResponse?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedVariantIds: Set<String> = []
    @State private var isSaving = false
    
    private func isVariantOwned(_ variantUuid: String, status: CritterStatus) -> Bool {
        ownedVariants.contains { $0.variantUuid == variantUuid && $0.status == status }
    }
    
    private var hasOwnedVariants: Bool {
        guard let variants = critterData?.variants else { return false }
        return variants.contains { variant in
            isVariantOwned(variant.uuid, status: targetStatus)
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading variants...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    ContentUnavailableView {
                        Label("Error", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Retry") {
                            Task { await loadVariants() }
                        }
                    }
                } else if let data = critterData {
                    pickerContent(data)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .task {
            await loadVariants()
        }
        .overlay {
            if isSaving {
                ZStack {
                    Color.black.opacity(0.3)
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Saving...")
                            .font(.subheadline)
                    }
                    .padding(20)
                    .background(Color(uiColor: .systemBackground))
                    .cornerRadius(12)
                }
                .ignoresSafeArea()
            }
        }
    }
    
    @ViewBuilder
    private func pickerContent(_ data: CritterVariantsResponse) -> some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text(data.critter.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let familyName = data.critter.familyName {
                    Text(familyName)
                        .font(.subheadline)
                        .foregroundColor(.calicoTextSecondary)
                }
                
                Text("Select variants to add to \(targetStatus == .collection ? "Collection" : "Wishlist")")
                    .font(.subheadline)
                    .foregroundColor(.calicoTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            
            // Variants list
            if data.variants.isEmpty {
                ContentUnavailableView(
                    "No Variants Available",
                    systemImage: "photo.stack",
                    description: Text("This critter has no variants yet")
                )
            } else {
                List {
                    ForEach(data.variants) { variant in
                        VariantRowOnline(
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
                if !selectedVariantIds.isEmpty || hasOwnedVariants {
                    Button {
                        Task { await saveSelection(data) }
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
                    .disabled(isSaving)
                }
                
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.calicoTextSecondary)
            }
            .padding()
        }
    }
    
    // MARK: - Data Loading
    
    private func loadVariants() async {
        isLoading = true
        errorMessage = nil
        
        print("🔍 Loading variants for critter: \(critterUuid)")
        
        do {
            critterData = try await BrowseService.shared.fetchCritterVariants(critterUuid: critterUuid)
            print("✅ Got response: \(String(describing: critterData))")
            print("✅ Variants count: \(critterData?.variants.count ?? 0)")
            
            // Pre-select already owned variants
            if let variants = critterData?.variants {
                selectedVariantIds = Set(
                    variants
                        .filter { isVariantOwned($0.uuid, status: targetStatus) }
                        .map { $0.uuid }
                )
            }
        } catch {
            print("❌ Error: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Helper Methods
    
    private func toggleVariant(_ uuid: String) {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        
        if selectedVariantIds.contains(uuid) {
            selectedVariantIds.remove(uuid)
        } else {
            selectedVariantIds.insert(uuid)
        }
    }
    
    private func saveSelection(_ data: CritterVariantsResponse) async {
        isSaving = true
        
        var addedCount = 0
        var removedCount = 0
        
        let variants = data.variants
        let critter = data.critter
        
        // Get previously owned variant UUIDs for this critter & status
        let previouslyOwned = Set(
            variants
                .filter { isVariantOwned($0.uuid, status: targetStatus) }
                .map { $0.uuid }
        )
        
        // Add selected variants (that weren't already owned)
        for variantUuid in selectedVariantIds {
            guard let variant = variants.first(where: { $0.uuid == variantUuid }) else { continue }
            
            if !previouslyOwned.contains(variantUuid) {
                do {
                    try await OwnedVariant.create(
                        variant: variant,
                        critter: critter,
                        familyId: critter.familyUuid ?? "",
                        status: targetStatus,
                        in: modelContext
                    )
                    addedCount += 1
                } catch {
                    AppLogger.error("Failed to add variant: \(error)")
                }
            }
        }
        
        // Remove deselected variants (that were previously owned)
        for variantUuid in previouslyOwned {
            if !selectedVariantIds.contains(variantUuid) {
                try? OwnedVariant.remove(variantUuid: variantUuid, in: modelContext)
                removedCount += 1
            }
        }
        
        // Show appropriate toast
        let statusName = targetStatus == .collection ? "Collection" : "Wishlist"
        
        if addedCount > 0 {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            ToastManager.shared.show("✓ Added \(addedCount) to \(statusName)", type: .success)
        } else if removedCount > 0 {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            ToastManager.shared.show("Removed \(removedCount) from \(statusName)", type: .info)
        }
        
        isSaving = false
        dismiss()
    }
}

// MARK: - Variant Row (Online Version)
struct VariantRowOnline: View {
    let variant: VariantResponse
    let isSelected: Bool
    let isOwned: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .blue : .gray)
                .font(.title3)
            
            // Variant image
            if let urlString = variant.thumbnailUrl ?? variant.imageUrl,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    default:
                        placeholderView
                    }
                }
                .frame(width: 60, height: 60)
            } else {
                placeholderView
            }
            
            // Variant info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(variant.name)
                        .font(.headline)
                    
                    if variant.isPrimary == true {
                        Text("Primary")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(4)
                    }
                    
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
                        .lineLimit(1)
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
    
    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.2))
            .frame(width: 60, height: 60)
            .overlay {
                Image(systemName: "photo")
                    .foregroundColor(.gray)
            }
    }
}

#Preview {
    Text("Picker Preview")
        .sheet(isPresented: .constant(true)) {
            VariantPickerSheet(
                critterUuid: "test-uuid",
                targetStatus: .collection
            )
        }
}
