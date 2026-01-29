//
//  SearchResultsList.swift
//  LottaPaws
//
//  Search results list with pagination
//

import SwiftUI

struct SearchResultsList: View {
    let results: [SearchResultResponse]
    let searchText: String
    let isSearching: Bool
    let error: String?
    let currentPage: Int
    let totalPages: Int
    let onLoadMore: () -> Void
    let onCollectionAction: (SearchResultResponse) -> Void
    let onWishlistAction: (SearchResultResponse) -> Void
    let isOwnedCheck: (String) -> Bool
    
    var body: some View {
        if isSearching && results.isEmpty {
            VStack(spacing: LottaPawsTheme.spacingMD) {
                ProgressView()
                    .tint(.primaryPink)
                Text("Searching...")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = error, results.isEmpty {
            LPEmptyState(
                icon: "exclamationmark.triangle",
                title: "Search Error",
                message: error
            )
        } else if results.isEmpty && !searchText.isEmpty {
            LPEmptyState(
                icon: "magnifyingglass",
                title: "No Results",
                message: "No variants found for \"\(searchText)\""
            )
        } else {
            List {
                ForEach(results) { result in
                    SearchResultRow(
                        result: result,
                        isOwned: isOwnedCheck(result.variantUuid)
                    )
                    .swipeActions(edge: .leading) {
                        Button {
                            onCollectionAction(result)
                        } label: {
                            Label("Collection", systemImage: "star.fill")
                        }
                        .tint(.secondaryBlue)
                    }
                    .swipeActions(edge: .trailing) {
                        Button {
                            onWishlistAction(result)
                        } label: {
                            Label("Wishlist", systemImage: "heart.fill")
                        }
                        .tint(.primaryPink)
                    }
                    .onAppear {
                        if result.id == results.last?.id && currentPage < totalPages {
                            onLoadMore()
                        }
                    }
                }
                
                if isSearching && !results.isEmpty {
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
