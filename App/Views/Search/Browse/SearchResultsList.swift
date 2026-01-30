//
//  SearchResultsList.swift
//  LottaPaws
//
//  Search results list showing critters with matching variants
//

import SwiftUI

struct SearchResultsList: View {
    let results: [CritterSearchResult]
    let searchText: String
    let isSearching: Bool
    let error: String?
    let currentPage: Int
    let totalPages: Int
    let onLoadMore: () -> Void
    let onCritterTap: (CritterSearchResult) -> Void
    let collectionCountFor: (String) -> Int
    let wishlistCountFor: (String) -> Int
    
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
                message: "No critters found for \"\(searchText)\""
            )
        } else {
            List {
                ForEach(results) { result in
                    SearchCritterRow(
                        result: result,
                        collectionCount: collectionCountFor(result.critterUuid),
                        wishlistCount: wishlistCountFor(result.critterUuid)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onCritterTap(result)
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
