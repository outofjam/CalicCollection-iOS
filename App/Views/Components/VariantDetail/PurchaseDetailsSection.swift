//
//  PurchaseDetailsSection.swift
//  CalicCollectionV2
//
//  Created by Ismail Dawoodjee on 2026-01-29.
//


//
//  PurchaseDetailsSection.swift
//  LottaPaws
//
//  Displays and manages purchase details for owned variants.
//

import SwiftUI
import SwiftData

struct PurchaseDetailsSection: View {
    let ownedVariant: OwnedVariant
    let hasPurchaseDetails: Bool
    @Binding var showingPurchaseDetails: Bool
    let modelContext: ModelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: LottaPawsTheme.spacingMD) {
            // Header
            HStack {
                Text("Purchase Details")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Button {
                    showingPurchaseDetails = true
                } label: {
                    Text(hasPurchaseDetails ? "Edit" : "Add")
                        .font(.subheadline)
                        .foregroundColor(.primaryPink)
                }
            }
            
            // Content
            if hasPurchaseDetails {
                purchaseDetailsContent
            } else {
                Text("Tap 'Add' to track purchase details")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(LottaPawsTheme.spacingLG)
        .background(Color.backgroundSecondary)
        .cornerRadius(LottaPawsTheme.radiusMD)
    }
    
    @ViewBuilder
    private var purchaseDetailsContent: some View {
        if let price = ownedVariant.pricePaid {
            InfoRow(label: "Price Paid", value: String(format: "$%.2f", price))
        }
        
        if let date = ownedVariant.purchaseDate {
            InfoRow(label: "Purchase Date", value: date.formatted(date: .abbreviated, time: .omitted))
        }
        
        if let location = ownedVariant.purchaseLocation {
            InfoRow(label: "Store", value: location)
        }
        
        if let condition = ownedVariant.condition {
            InfoRow(label: "Condition", value: condition)
        }
        
        if let notes = ownedVariant.notes {
            VStack(alignment: .leading, spacing: LottaPawsTheme.spacingXS) {
                Text("Notes")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                Text(notes)
                    .font(.body)
                    .foregroundColor(.textPrimary)
            }
        }
        
        // Quantity stepper
        quantityStepper
    }
    
    private var quantityStepper: some View {
        HStack(spacing: LottaPawsTheme.spacingLG) {
            Text("Quantity")
                .font(.caption)
                .foregroundColor(.textSecondary)
            
            Spacer()
            
            HStack(spacing: LottaPawsTheme.spacingMD) {
                Button {
                    if ownedVariant.quantity > 1 {
                        ownedVariant.quantity -= 1
                        try? modelContext.save()
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(ownedVariant.quantity > 1 ? .primaryPink : .textTertiary)
                }
                .disabled(ownedVariant.quantity <= 1)
                
                Text("\(ownedVariant.quantity)")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                    .frame(minWidth: 30)
                
                Button {
                    ownedVariant.quantity += 1
                    try? modelContext.save()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.primaryPink)
                }
            }
        }
    }
}

#Preview {
    VStack {
        // Would need a mock OwnedVariant for preview
        Text("PurchaseDetailsSection Preview")
    }
}