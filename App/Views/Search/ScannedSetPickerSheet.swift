//
//  ScannedSetPickerSheet.swift
//  LottaPaws
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
                VStack(spacing: LottaPawsTheme.spacingSM) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.successGreen)
                    
                    Text(setResponse.set.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                    
                    Text("Select variants to add to \(targetStatus == .collection ? "Collection" : "Wishlist")")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(LottaPawsTheme.spacingLG)
                
                // Variants list
                if setResponse.variants.isEmpty {
                    LPEmptyState(
                        icon: "photo.stack",
                        title: "No Variants",
                        message: "This set has no variants"
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
                VStack(spacing: LottaPawsTheme.spacingSM) {
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
                        .padding(.vertical, LottaPawsTheme.spacingMD)
                        .background(selectedVariantIds.isEmpty ? Color.textTertiary : (targetStatus == .collection ? Color.secondaryBlue : Color.primaryPink))
                        .cornerRadius(LottaPawsTheme.radiusSM)
                    }
                    .disabled(isLoading)
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.textSecondary)
                }
                .padding(LottaPawsTheme.spacingLG)
            }
            .background(Color.backgroundPrimary)
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
        HStack(spacing: LottaPawsTheme.spacingMD) {
            // Checkbox
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .primaryPink : .textTertiary)
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
                            .clipShape(RoundedRectangle(cornerRadius: LottaPawsTheme.radiusSM))
                    default:
                        placeholderView
                    }
                }
                .frame(width: 60, height: 60)
            } else {
                placeholderView
            }
            
            // Variant info
            VStack(alignment: .leading, spacing: LottaPawsTheme.spacingXS) {
                HStack {
                    Text(variant.critter.name)
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    
                    if isOwned {
                        Text("✓ Owned")
                            .font(.caption2)
                            .padding(.horizontal, LottaPawsTheme.spacingSM)
                            .padding(.vertical, 2)
                            .background(Color.successGreen.opacity(0.15))
                            .foregroundColor(.successGreen)
                            .cornerRadius(4)
                    }
                }
                
                if let role = variant.critter.role {
                    Text(role)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                
                Text(variant.critter.family.name)
                    .font(.caption2)
                    .foregroundColor(.textTertiary)
            }
            
            Spacer()
        }
        .padding(.vertical, LottaPawsTheme.spacingSM)
    }
    
    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: LottaPawsTheme.radiusSM)
            .fill(Color.backgroundTertiary)
            .frame(width: 60, height: 60)
            .overlay {
                Image(systemName: "photo")
                    .foregroundColor(.textTertiary)
            }
    }
}

#Preview {
    Text("Preview")
}
