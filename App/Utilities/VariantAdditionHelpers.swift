//
//  VariantAdditionHelpers.swift
//  LottaPaws
//
//  Helper methods for adding variants to collection/wishlist
//

import SwiftUI
import SwiftData

struct VariantAdditionHelpers {
    
    /// Add a single variant directly (when critter has only 1 variant)
    /// Returns the critter info for birthday checking
    @discardableResult
    static func addSingleVariant(
        critterUuid: String,
        status: CritterStatus,
        modelContext: ModelContext,
        ownedVariants: [OwnedVariant]
    ) async throws -> CritterInfo {
        let response = try await BrowseService.shared.fetchCritterVariants(critterUuid: critterUuid)
        
        guard let variant = response.variants.first else {
            throw VariantAdditionError.noVariantFound
        }
        
        // Check if already owned
        if ownedVariants.contains(where: { $0.variantUuid == variant.uuid }) {
            throw VariantAdditionError.alreadyOwned(status: status)
        }
        
        // Create OwnedVariant
        let owned = OwnedVariant(
            variantUuid: variant.uuid,
            critterUuid: response.critter.uuid,
            critterName: response.critter.name,
            variantName: variant.name,
            familyId: response.critter.familyUuid ?? "",
            familyName: response.critter.familyName,
            familySpecies: nil,
            memberType: response.critter.memberType,
            role: nil,
            epochId: variant.epochId,
            setName: variant.setName,
            imageURL: variant.imageUrl,
            thumbnailURL: variant.thumbnailUrl,
            status: status
        )
        
        modelContext.insert(owned)
        try modelContext.save()
        
        // Success feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Trigger confetti if adding to collection
        if status == .collection && AppSettings.shared.showConfetti {
            ConfettiManager.shared.trigger()
        }
        
        // Check for birthday match (only for collection, not wishlist)
        if status == .collection {
            await MainActor.run {
                BirthdayMatchManager.shared.checkAndCelebrate(
                    critterName: response.critter.name,
                    critterBirthday: response.critter.birthday
                )
            }
        }
        
        return response.critter
    }
}

// MARK: - Error Types

enum VariantAdditionError: LocalizedError {
    case noVariantFound
    case alreadyOwned(status: CritterStatus)
    
    var errorDescription: String? {
        switch self {
        case .noVariantFound:
            return "No variant found"
        case .alreadyOwned(let status):
            return "Already in your \(status == .collection ? "collection" : "wishlist")"
        }
    }
}
