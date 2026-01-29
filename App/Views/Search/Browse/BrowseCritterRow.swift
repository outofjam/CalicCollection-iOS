//
//  BrowseCritterRow.swift
//  LottaPaws
//
//  Created by Ismail Dawoodjee on 2026-01-28.
//

import SwiftUI

// MARK: - Browse Critter Row
struct BrowseCritterRow: View {
    let critter: BrowseCritterResponse
    let collectionCount: Int
    let wishlistCount: Int
    
    private var ownedCount: Int { collectionCount + wishlistCount }
    private var hasOwned: Bool { ownedCount > 0 }
    
    var body: some View {
        HStack(spacing: LottaPawsTheme.spacingMD) {
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
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: LottaPawsTheme.radiusSM))
            } else {
                placeholderView
                    .frame(width: 60, height: 60)
            }
            
            // Info
            VStack(alignment: .leading, spacing: LottaPawsTheme.spacingXS) {
                Text(critter.name)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                if let familyName = critter.familyName {
                    Text(familyName)
                        .font(.subheadline)
                        .foregroundColor(.primaryPink)
                }
                
                HStack(spacing: LottaPawsTheme.spacingXS) {
                    Image(systemName: "photo.stack")
                        .font(.system(size: 10))
                    Text("\(ownedCount)/\(critter.variantsCount) variants")
                        .font(.caption2)
                }
                .foregroundColor(hasOwned ? .successGreen : .textSecondary)
            }
            
            Spacer()
            
            // Collection/Wishlist indicators
            HStack(spacing: 4) {
                if collectionCount > 0 {
                    Image(systemName: "star.fill")
                        .foregroundColor(.secondaryBlue)
                        .font(.system(size: 14))
                }
                if wishlistCount > 0 {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.primaryPink)
                        .font(.system(size: 14))
                }
            }
        }
        .padding(.vertical, LottaPawsTheme.spacingXS)
    }
    
    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: LottaPawsTheme.radiusSM)
            .fill(Color.backgroundTertiary)
            .overlay {
                Image(systemName: "pawprint.fill")
                    .foregroundColor(.textTertiary)
            }
    }
}

#Preview {
    VStack {
        BrowseCritterRow(
            critter: BrowseCritterResponse(
                uuid: "1",
                name: "Stella Hopscotch",
                familyId: "1",
                familyName: "Chocolate Rabbit",
                memberType: "girl",
                thumbnailUrl: nil,
                variantsCount: 3
            ),
            collectionCount: 2,
            wishlistCount: 1
        )
        
        BrowseCritterRow(
            critter: BrowseCritterResponse(
                uuid: "2",
                name: "Freya Hopscotch",
                familyId: "1",
                familyName: "Chocolate Rabbit",
                memberType: "mother",
                thumbnailUrl: nil,
                variantsCount: 2
            ),
            collectionCount: 0,
            wishlistCount: 1
        )
        
        BrowseCritterRow(
            critter: BrowseCritterResponse(
                uuid: "3",
                name: "Coco Hopscotch",
                familyId: "1",
                familyName: "Chocolate Rabbit",
                memberType: "father",
                thumbnailUrl: nil,
                variantsCount: 2
            ),
            collectionCount: 0,
            wishlistCount: 0
        )
    }
    .padding()
}
