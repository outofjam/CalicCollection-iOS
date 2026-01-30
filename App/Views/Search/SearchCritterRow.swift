//
//  SearchCritterRow.swift
//  CalicCollectionV2
//
//  Created by Ismail Dawoodjee on 2026-01-30.
//


//
//  SearchCritterRow.swift
//  LottaPaws
//
//  Row displaying a critter in search results with matching variant count
//

import SwiftUI

struct SearchCritterRow: View {
    let result: CritterSearchResult
    let collectionCount: Int
    let wishlistCount: Int
    
    private var ownedCount: Int { collectionCount + wishlistCount }
    private var hasOwned: Bool { ownedCount > 0 }
    
    var body: some View {
        HStack(spacing: LottaPawsTheme.spacingMD) {
            // Thumbnail
            if let urlString = result.thumbnailUrl, let url = URL(string: urlString) {
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
                Text(result.critterName)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                if let familyName = result.familyName {
                    Text(familyName)
                        .font(.subheadline)
                        .foregroundColor(.primaryPink)
                }
                
                HStack(spacing: LottaPawsTheme.spacingXS) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 10))
                    Text("\(result.matchingVariantsCount) variant\(result.matchingVariantsCount == 1 ? "" : "s") match")
                        .font(.caption2)
                }
                .foregroundColor(.textSecondary)
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
        SearchCritterRow(
            result: CritterSearchResult(
                critterUuid: "123",
                critterName: "Flora Rabbit",
                memberType: "Babies",
                birthday: "December 3",
                hobby: "Painting",
                familyUuid: "456",
                familyName: "Flora Rabbit",
                species: "Rabbit",
                thumbnailUrl: nil,
                matchingVariantsCount: 2,
                matchingVariants: []
            ),
            collectionCount: 1,
            wishlistCount: 0
        )
        
        SearchCritterRow(
            result: CritterSearchResult(
                critterUuid: "789",
                critterName: "Stella Hopscotch",
                memberType: "Sister",
                birthday: nil,
                hobby: nil,
                familyUuid: "456",
                familyName: "Chocolate Rabbit",
                species: "Rabbit",
                thumbnailUrl: nil,
                matchingVariantsCount: 1,
                matchingVariants: []
            ),
            collectionCount: 0,
            wishlistCount: 0
        )
    }
    .padding()
}