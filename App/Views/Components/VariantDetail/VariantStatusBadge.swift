//
//  VariantStatusBadge.swift
//  CalicCollectionV2
//
//  Created by Ismail Dawoodjee on 2026-01-29.
//


//
//  VariantStatusBadge.swift
//  LottaPaws
//
//  Displays collection/wishlist status with added date.
//

import SwiftUI

struct VariantStatusBadge: View {
    let status: CritterStatus
    let addedDate: Date
    
    var body: some View {
        HStack {
            Image(systemName: status == .collection ? "star.fill" : "heart.fill")
                .foregroundColor(status == .collection ? .secondaryBlue : .primaryPink)
            
            Text(status == .collection ? "In Collection" : "On Wishlist")
                .fontWeight(.medium)
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            Text("Added \(addedDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundColor(.textTertiary)
        }
        .padding(LottaPawsTheme.spacingLG)
        .background(
            RoundedRectangle(cornerRadius: LottaPawsTheme.radiusMD)
                .fill(status == .collection 
                      ? Color.secondaryBlueLight.opacity(0.5) 
                      : Color.primaryPinkLight.opacity(0.5))
        )
    }
}

#Preview("Collection") {
    VStack(spacing: 20) {
        VariantStatusBadge(status: .collection, addedDate: Date())
        VariantStatusBadge(status: .wishlist, addedDate: Date().addingTimeInterval(-86400 * 7))
    }
    .padding()
}