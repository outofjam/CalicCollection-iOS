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
    let ownedCount: Int
    
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
            
            // Owned indicator
            if hasOwned {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.successGreen)
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
