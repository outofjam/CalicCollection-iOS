//
//  BottomActionBar.swift
//  LottaPaws
//
//  Created by Ismail Dawoodjee on 2026-01-27.
//

import SwiftUI

struct BottomActionBar: View {
    let isInCollection: Bool
    let isInWishlist: Bool
    let variantName: String
    let onAddToCollection: () -> Void
    let onAddToWishlist: () -> Void
    let onMoveToWishlist: () -> Void
    let onRemove: () -> Void
    
    @State private var showingRemoveAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            LPDivider()
            
            HStack(spacing: LottaPawsTheme.spacingMD) {
                // Primary action button
                if !isInCollection {
                    Button {
                        onAddToCollection()
                    } label: {
                        HStack {
                            Image(systemName: "star.fill")
                            Text("Add to Collection")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.primaryPink)
                        .cornerRadius(LottaPawsTheme.radiusMD)
                    }
                } else {
                    Button {
                        onMoveToWishlist()
                    } label: {
                        HStack {
                            Image(systemName: "heart.fill")
                            Text("Move to Wishlist")
                        }
                        .font(.headline)
                        .foregroundColor(.primaryPink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.primaryPinkLight.opacity(0.5))
                        .cornerRadius(LottaPawsTheme.radiusMD)
                        .overlay(
                            RoundedRectangle(cornerRadius: LottaPawsTheme.radiusMD)
                                .stroke(Color.primaryPink, lineWidth: 1.5)
                        )
                    }
                }
                
                // Secondary actions menu
                if isInCollection || isInWishlist {
                    Menu {
                        if !isInWishlist && !isInCollection {
                            Button {
                                onAddToWishlist()
                            } label: {
                                Label("Add to Wishlist", systemImage: "heart")
                            }
                        }
                        
                        Button(role: .destructive) {
                            showingRemoveAlert = true
                        } label: {
                            Label("Remove from \(isInCollection ? "Collection" : "Wishlist")", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.title2)
                            .foregroundColor(.textSecondary)
                            .frame(width: 50, height: 50)
                            .background(Color.backgroundSecondary)
                            .cornerRadius(LottaPawsTheme.radiusMD)
                    }
                } else if !isInCollection {
                    Button {
                        onAddToWishlist()
                    } label: {
                        Image(systemName: "heart")
                            .font(.title2)
                            .foregroundColor(.primaryPink)
                            .frame(width: 50, height: 50)
                            .background(Color.primaryPinkLight.opacity(0.5))
                            .cornerRadius(LottaPawsTheme.radiusMD)
                            .overlay(
                                RoundedRectangle(cornerRadius: LottaPawsTheme.radiusMD)
                                    .stroke(Color.primaryPink, lineWidth: 1.5)
                            )
                    }
                }
            }
            .padding(.horizontal, LottaPawsTheme.spacingLG)
            .padding(.vertical, LottaPawsTheme.spacingMD)
        }
        .background(.regularMaterial)
        .alert("Remove \(variantName)?", isPresented: $showingRemoveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                onRemove()
            }
        } message: {
            Text("This will remove \(variantName) from your \(isInCollection ? "collection" : "wishlist").")
        }
    }
}
