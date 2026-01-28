//
//  BrowseCritterRow.swift
//  CalicCollectionV2
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
        HStack(spacing: 12) {
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
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                placeholderView
                    .frame(width: 60, height: 60)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(critter.name)
                    .font(.headline)
                
                if let familyName = critter.familyName {
                    Text(familyName)
                        .font(.subheadline)
                        .foregroundColor(.calicoTextSecondary)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "photo.stack")
                        .font(.system(size: 10))
                    Text("\(ownedCount)/\(critter.variantsCount) variants")
                        .font(.caption2)
                }
                .foregroundColor(hasOwned ? .blue : .secondary)
            }
            
            Spacer()
            
            // Owned indicator
            if hasOwned {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.calicoPrimary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.2))
            .overlay {
                Image(systemName: "pawprint.fill")
                    .foregroundColor(.gray)
            }
    }
}