//
//  BottomActionBar.swift
//  CalicCollectionV2
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
            Divider()
            
            HStack(spacing: 12) {
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
                        .background(Color.calicoPrimary)
                        .cornerRadius(12)
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
                        .foregroundColor(.pink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.pink.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.pink, lineWidth: 1.5)
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
                            .foregroundColor(.calicoTextSecondary)
                            .frame(width: 50, height: 50)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(12)
                    }
                } else if !isInCollection {
                    Button {
                        onAddToWishlist()
                    } label: {
                        Image(systemName: "heart")
                            .font(.title2)
                            .foregroundColor(.pink)
                            .frame(width: 50, height: 50)
                            .background(Color.pink.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.pink, lineWidth: 1.5)
                            )
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
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