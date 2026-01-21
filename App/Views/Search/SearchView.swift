import SwiftUI
import SwiftData

struct SearchView: View {
    @Binding var searchText: String
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var syncService: SyncService
    
    @Query(sort: \Critter.name) private var allCritters: [Critter]
    @Query private var ownedVariants: [OwnedVariant]
    
    @State private var showingVariantPicker = false
    @State private var selectedCritter: Critter?
    @State private var pickerTargetStatus: CritterStatus = .collection
    
    var body: some View {
        ZStack {
            if syncService.isSyncing {
                ProgressView("Syncing critters...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = syncService.syncError {
                ContentUnavailableView(
                    "Sync Error",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else if allCritters.isEmpty {
                ContentUnavailableView(
                    "No Critters Yet",
                    systemImage: "pawprint.fill",
                    description: Text("Pull down to sync from server")
                )
            } else {
                List {
                    ForEach(filteredCritters) { critter in
                        NavigationLink {
                            CritterDetailView(critter: critter)
                        } label: {
                            CritterRow(
                                critter: critter,
                                ownedVariants: ownedVariantsFor(critter)
                            )
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                handleCollectionAction(for: critter)
                            } label: {
                                Label("Collection", systemImage: "star.fill")
                            }
                            .tint(.blue)
                        }
                        .swipeActions(edge: .trailing) {
                            Button {
                                handleWishlistAction(for: critter)
                            } label: {
                                Label("Wishlist", systemImage: "heart.fill")
                            }
                            .tint(.pink)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Search")
        .searchable(text: $searchText, prompt: "Search critters...")
        .refreshable {
            await syncService.syncCritters(modelContext: modelContext, force: true)
        }
        .sheet(item: $selectedCritter) { critter in
            VariantPickerSheet(
                critter: critter,
                targetStatus: pickerTargetStatus
            )
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredCritters: [Critter] {
        if searchText.isEmpty {
            return allCritters
        }
        
        let lowercased = searchText.lowercased()
        return allCritters.filter { critter in
            critter.name.lowercased().contains(lowercased) ||
            (critter.familyName?.lowercased().contains(lowercased) ?? false) ||
            (critter.familySpecies?.lowercased().contains(lowercased) ?? false) ||
            critter.memberType.lowercased().contains(lowercased) ||
            (critter.role?.lowercased().contains(lowercased) ?? false)
        }
    }
    
    private func ownedVariantsFor(_ critter: Critter) -> [OwnedVariant] {
        ownedVariants.filter { $0.critterUuid == critter.uuid }
    }
    
    // MARK: - Actions
    
    private func handleCollectionAction(for critter: Critter) {
        if critter.variantsCount > 0 {
            // Has variants - show picker
            pickerTargetStatus = .collection
            selectedCritter = critter
        } else {
            // No variants - add directly (future: handle critters without variants)
            print("⚠️ Critter has no variants - direct add not implemented yet")
        }
    }
    
    private func handleWishlistAction(for critter: Critter) {
        if critter.variantsCount > 0 {
            // Has variants - show picker
            pickerTargetStatus = .wishlist
            selectedCritter = critter
        } else {
            // No variants - add directly (future: handle critters without variants)
            print("⚠️ Critter has no variants - direct add not implemented yet")
        }
    }
}

// MARK: - Critter Row
struct CritterRow: View {
    let critter: Critter
    let ownedVariants: [OwnedVariant]
    
    private var hasInCollection: Bool {
        ownedVariants.contains { $0.status == .collection }
    }
    
    private var hasInWishlist: Bool {
        ownedVariants.contains { $0.status == .wishlist }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Placeholder for image (we'll add CritterImageView later)
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay {
                    Image(systemName: "pawprint.fill")
                        .foregroundColor(.gray)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(critter.name)
                    .font(.headline)
                
                HStack(spacing: 4) {
                    if let familyName = critter.familyName {
                        Text(familyName)
                        Text("•")
                    }
                    Text(critter.memberType)
                    if let role = critter.role {
                        Text("•")
                        Text(role)
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                // Variant count badge
                if critter.variantsCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "photo.stack")
                            .font(.system(size: 10))
                        Text("\(ownedVariants.count)/\(critter.variantsCount) variants")
                            .font(.caption2)
                    }
                    .foregroundColor(ownedVariants.isEmpty ? .secondary : .blue)
                }
            }
            
            Spacer()
            
            // Status indicators
            HStack(spacing: 8) {
                if hasInWishlist {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.pink)
                        .font(.caption)
                }
                if hasInCollection {
                    Image(systemName: "star.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        SearchView(searchText: .constant(""))
            .modelContainer(for: OwnedVariant.self, inMemory: true)
            .environmentObject(SyncService.shared)
    }
}
