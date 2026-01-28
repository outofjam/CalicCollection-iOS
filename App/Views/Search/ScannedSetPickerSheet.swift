//
//  ScannedSetPickerSheet.swift
//  CaliCollectionV2
//
//  Created by Ismail Dawoodjee on 2026-01-24.
//

import SwiftUI
import SwiftData

struct ScannedSetPickerSheet: View {
    let setResponse: SetResponse
    let targetStatus: CritterStatus
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query private var ownedVariants: [OwnedVariant]
    
    @State private var selectedVariantIds: Set<String> = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.calicoSuccess)
                    
                    Text(setResponse.set.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Select variants to add to \(targetStatus == .collection ? "Collection" : "Wishlist")")
                        .font(.subheadline)
                        .foregroundColor(.calicoTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                // Variants list
                if setResponse.variants.isEmpty {
                    ContentUnavailableView(
                        "No Variants",
                        systemImage: "photo.stack",
                        description: Text("This set has no variants")
                    )
                } else {
                    List {
                        ForEach(setResponse.variants) { variant in
                            ScannedVariantRow(
                                variant: variant,
                                isSelected: selectedVariantIds.contains(variant.uuid),
                                isOwned: isVariantOwned(variant.uuid)
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
                VStack(spacing: 8) {
                    Button {
                        Task {
                            await saveSelection()
                        }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: targetStatus == .collection ? "star.fill" : "heart.fill")
                                Text(selectedVariantIds.isEmpty ? "Skip" : "Add \(selectedVariantIds.count) to \(targetStatus == .collection ? "Collection" : "Wishlist")")
                            }
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedVariantIds.isEmpty ? Color.gray : (targetStatus == .collection ? Color.blue : Color.pink))
                        .cornerRadius(10)
                    }
                    .disabled(isLoading)
                    
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
            // Pre-select all variants that aren't already owned
            selectedVariantIds = Set(
                setResponse.variants
                    .filter { !isVariantOwned($0.uuid) }
                    .map { $0.uuid }
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func isVariantOwned(_ variantUuid: String) -> Bool {
        ownedVariants.contains { $0.variantUuid == variantUuid && $0.status == targetStatus }
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
    
    private func saveSelection() async {
        guard !selectedVariantIds.isEmpty else {
            dismiss()
            return
        }
        
        isLoading = true
        
        var addedCount = 0
        
        for variantUuid in selectedVariantIds {
            guard let setVariant = setResponse.variants.first(where: { $0.uuid == variantUuid }) else {
                continue
            }
            
            // Add to collection/wishlist if not already owned
            if !isVariantOwned(variantUuid) {
                do {
                    try await OwnedVariant.create(
                        from: setVariant,
                        status: targetStatus,
                        in: modelContext
                    )
                    addedCount += 1
                } catch {
                    AppLogger.error("Failed to add variant: \(error)")
                }
            }
        }
        
        isLoading = false
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Show toast
        if addedCount > 0 {
            ToastManager.shared.show(
                "✓ Added \(addedCount) variant\(addedCount == 1 ? "" : "s") to \(targetStatus == .collection ? "Collection" : "Wishlist")",
                type: .success
            )
        }
        
        dismiss()
    }
}

// MARK: - Scanned Variant Row
struct ScannedVariantRow: View {
    let variant: SetVariant
    let isSelected: Bool
    let isOwned: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .blue : .gray)
                .font(.title3)
            
            // Variant image
            if let urlString = variant.thumbnailURL ?? variant.imageURL,
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
                    Text(variant.critter.name)
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
                
                if let role = variant.critter.role {
                    Text(role)
                        .font(.caption)
                        .foregroundColor(.calicoTextSecondary)
                }
                
                Text(variant.critter.family.name)
                    .font(.caption2)
                    .foregroundColor(.calicoTextSecondary)
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
    Text("Preview")
}
