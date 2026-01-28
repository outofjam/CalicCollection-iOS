//
//  SearchResultRow.swift
//  CalicCollectionV2
//
//  Created by Ismail Dawoodjee on 2026-01-28.
//


import SwiftUI

// MARK: - Search Result Row
struct SearchResultRow: View {
    let result: SearchResultResponse
    let isOwned: Bool
    
    var body: some View {
        HStack(spacing: 12) {
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
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                placeholderView
                    .frame(width: 60, height: 60)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(result.variantName)
                    .font(.headline)
                
                if let critterName = result.critterName {
                    Text(critterName)
                        .font(.subheadline)
                        .foregroundColor(.calicoTextSecondary)
                }
                
                if let familyName = result.familyName {
                    Text(familyName)
                        .font(.caption)
                        .foregroundColor(.calicoTextSecondary)
                }
            }
            
            Spacer()
            
            // Owned indicator
            if isOwned {
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
                Image(systemName: "photo")
                    .foregroundColor(.gray)
            }
    }
}