//
//  SearchResultRow.swift
//  LottaPaws
//
//  Created by Ismail Dawoodjee on 2026-01-28.
//

import SwiftUI

// MARK: - Search Result Row
struct SearchResultRow: View {
    let result: SearchResultResponse
    let isOwned: Bool
    
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
                Text(result.variantName)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                if let critterName = result.critterName {
                    Text(critterName)
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                
                if let familyName = result.familyName {
                    Text(familyName)
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                }
            }
            
            Spacer()
            
            // Owned indicator
            if isOwned {
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
                Image(systemName: "photo")
                    .foregroundColor(.textTertiary)
            }
    }
}
