import SwiftUI
import SwiftData

enum CollectionViewMode {
    case list
    case gallery
    case stats
}

/// Reusable view for displaying owned variants (Collection or Wishlist)
struct OwnedVariantsView: View {
    let status: CritterStatus
    let title: String
    let emptyIcon: String
    let emptyDescription: String
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \OwnedVariant.critterName) private var ownedVariants: [OwnedVariant]
    
    @State private var viewMode: CollectionViewMode = .list
    @State private var selectedVariant: OwnedVariant?
    
    private var filteredVariants: [OwnedVariant] {
        ownedVariants.filter { $0.status == status }
    }
    
    // Group variants by family
    private var groupedVariants: [String: [OwnedVariant]] {
        Dictionary(grouping: filteredVariants) { variant in
            // Get the family name from the critter
            if let critter = getCritter(for: variant),
               let familyName = critter.familyName {
                return familyName
            }
            return "Unknown Family"
        }
    }
    
    private var sortedFamilyNames: [String] {
        groupedVariants.keys.sorted()
    }
    
    private var iconForMode: String {
        switch viewMode {
        case .list:
            return "square.grid.2x2" // Next: gallery
        case .gallery:
            return status == .collection ? "chart.bar" : "list.bullet" // Next: stats (collection) or list (wishlist)
        case .stats:
            return "list.bullet" // Next: list
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if filteredVariants.isEmpty {
                    ContentUnavailableView(
                        title,
                        systemImage: emptyIcon,
                        description: Text(emptyDescription)
                    )
                } else {
                    Group {
                        switch viewMode {
                        case .list:
                            CollectionListView(
                                groupedVariants: groupedVariants,
                                sortedGroupNames: sortedFamilyNames,
                                selectedVariant: $selectedVariant
                            )
                        case .gallery:
                            CollectionGalleryView(
                                groupedVariants: groupedVariants,
                                sortedGroupNames: sortedFamilyNames,
                                selectedVariant: $selectedVariant
                            )
                        case .stats:
                            StatsView(variants: filteredVariants)
                        }
                    }
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation {
                            if status == .collection {
                                // Collection has 3 modes: list → gallery → stats → list
                                switch viewMode {
                                case .list:
                                    viewMode = .gallery
                                case .gallery:
                                    viewMode = .stats
                                case .stats:
                                    viewMode = .list
                                }
                            } else {
                                // Wishlist has 2 modes: list → gallery → list
                                viewMode = viewMode == .list ? .gallery : .list
                            }
                        }
                    } label: {
                        Image(systemName: iconForMode)
                    }
                }
            }
            .sheet(item: $selectedVariant) { variant in
                if let critter = getCritter(for: variant),
                   let critterVariant = getCritterVariant(for: variant) {
                    VariantDetailView(variant: critterVariant, critter: critter)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getCritter(for ownedVariant: OwnedVariant) -> Critter? {
        let critterUuid = ownedVariant.critterUuid
        let descriptor = FetchDescriptor<Critter>(
            predicate: #Predicate { $0.uuid == critterUuid }
        )
        return try? modelContext.fetch(descriptor).first
    }
    
    private func getCritterVariant(for ownedVariant: OwnedVariant) -> CritterVariant? {
        let variantUuid = ownedVariant.variantUuid
        let descriptor = FetchDescriptor<CritterVariant>(
            predicate: #Predicate { $0.uuid == variantUuid }
        )
        return try? modelContext.fetch(descriptor).first
    }
}

#Preview {
    OwnedVariantsView(
        status: .collection,
        title: "Collection",
        emptyIcon: "star",
        emptyDescription: "Critters you add to your collection will appear here"
    )
    .modelContainer(for: OwnedVariant.self, inMemory: true)
}
