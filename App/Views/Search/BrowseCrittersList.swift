//
//  BrowseCrittersList.swift
//  LottaPaws
//
//  Browse critters list with pagination
//

import SwiftUI
import SwiftData

struct BrowseCrittersList: View {
    let critters: [BrowseCritterResponse]
    let isLoading: Bool
    let error: String?
    let currentPage: Int
    let totalPages: Int
    let onLoadMore: () -> Void
    let onRetry: () -> Void
    let onCollectionAction: (BrowseCritterResponse) -> Void
    let onWishlistAction: (BrowseCritterResponse) -> Void
    let collectionCountFor: (String) -> Int
    let wishlistCountFor: (String) -> Int
    
    var body: some View {
        if isLoading && critters.isEmpty {
            VStack(spacing: LottaPawsTheme.spacingMD) {
                ProgressView()
                    .tint(.primaryPink)
                Text("Loading critters...")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = error, critters.isEmpty {
            LPEmptyState(
                icon: "exclamationmark.triangle",
                title: "Error",
                message: error,
                buttonTitle: "Retry",
                buttonAction: onRetry
            )
        } else if critters.isEmpty {
            LPEmptyState(
                icon: "pawprint.fill",
                title: "No Critters",
                message: "No critters found"
            )
        } else {
            List {
                ForEach(critters) { critter in
                    NavigationLink {
                        CritterDetailView(critterUuid: critter.uuid)
                    } label: {
                        BrowseCritterRow(
                            critter: critter,
                            collectionCount: collectionCountFor(critter.uuid),
                            wishlistCount: wishlistCountFor(critter.uuid)
                        )
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            onCollectionAction(critter)
                        } label: {
                            Label("Collection", systemImage: "star.fill")
                        }
                        .tint(.secondaryBlue)
                    }
                    .swipeActions(edge: .trailing) {
                        Button {
                            onWishlistAction(critter)
                        } label: {
                            Label("Wishlist", systemImage: "heart.fill")
                        }
                        .tint(.primaryPink)
                    }
                    .onAppear {
                        if critter.id == critters.last?.id && currentPage < totalPages {
                            onLoadMore()
                        }
                    }
                }
                
                if isLoading && !critters.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(.primaryPink)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}
