import SwiftUI
import SwiftData

struct SearchView: View {
    @Binding var searchText: String
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var syncService: SyncService
    
    @Query(sort: \Critter.name) private var allCritters: [Critter]
    @Query private var allVariants: [CritterVariant]
    @Query private var ownedVariants: [OwnedVariant]
    
    @State private var showingVariantPicker = false
    @State private var selectedCritter: Critter?
    @State private var pickerTargetStatus: CritterStatus = .collection
    
    // Filters
    @State private var selectedFamily: String? = nil
    @State private var selectedMemberType: String? = nil
    
    // Barcode scanner
    @State private var showingBarcodeScanner = false
    @State private var scannedBarcode: String?
    @State private var scannedSet: SetResponse?
    @State private var showingScannedSetPicker = false
    @State private var isLoadingSet = false
    
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
                VStack(spacing: 0) {
                    // Filter chips
                    FilterChipsView(
                        selectedFamily: $selectedFamily,
                        selectedMemberType: $selectedMemberType,
                        availableFamilies: availableFamilies,
                        availableMemberTypes: availableMemberTypes
                    )
                    
                    // Results
                    if filteredCritters.isEmpty {
                        ContentUnavailableView(
                            "No Results",
                            systemImage: "magnifyingglass",
                            description: Text("Try adjusting your filters or search")
                        )
                    } else {
                        List {
                            ForEach(sortedFamilyNames, id: \.self) { familyName in
                                Section {
                                    // Family header as first tappable row
                                    NavigationLink {
                                        FamilyDetailView(familyName: familyName)
                                    } label: {
                                        HStack {
                                            Text(familyName)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            Spacer()
                                            if let critters = groupedCritters[familyName] {
                                                Text("\(critters.count)")
                                                    .font(.caption)
                                                    .foregroundColor(.calicoTextSecondary)
                                            }
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    
                                    // Critters
                                    if let critters = groupedCritters[familyName] {
                                        ForEach(critters) { critter in
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
                                                .tint(.calicoPrimary)
                                            }
                                            .swipeActions(edge: .trailing) {
                                                Button {
                                                    handleWishlistAction(for: critter)
                                                } label: {
                                                    Label("Wishlist", systemImage: "heart.fill")
                                                }
                                                .tint(.calicoSecondary)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                    }
                }
                
                // Floating barcode scan button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            showingBarcodeScanner = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 60, height: 60)
                                    .shadow(radius: 4)
                                
                                Image(systemName: "barcode.viewfinder")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("Search")
        .searchable(text: $searchText, prompt: "Search critters...")
        .sheet(item: $selectedCritter) { critter in
            VariantPickerSheet(
                critter: critter,
                targetStatus: pickerTargetStatus
            )
        }
        .fullScreenCover(isPresented: $showingBarcodeScanner) {
            BarcodeScannerView(scannedBarcode: $scannedBarcode)
        }
        .sheet(isPresented: $showingScannedSetPicker) {
            if let scannedSet = scannedSet {
                ScannedSetPickerSheet(
                    setResponse: scannedSet,
                    targetStatus: .collection
                )
            }
        }
        .onChange(of: scannedBarcode) { oldValue, newValue in
            if let barcode = newValue {
                Task {
                    await fetchScannedSet(barcode)
                }
            }
        }
        .overlay {
            if isLoadingSet {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading set...")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    .padding(20)
                    .background(Color(uiColor: .systemBackground))
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredCritters: [Critter] {
        var critters = allCritters
        
        // Apply family filter
        if let selectedFamily = selectedFamily {
            critters = critters.filter { $0.familyName == selectedFamily }
        }
        
        // Apply member type filter
        if let selectedMemberType = selectedMemberType {
            critters = critters.filter { $0.memberType == selectedMemberType }
        }
        
        // Apply search text
        if !searchText.isEmpty {
            let lowercased = searchText.lowercased()
            critters = critters.filter { critter in
                critter.name.lowercased().contains(lowercased) ||
                (critter.familyName?.lowercased().contains(lowercased) ?? false) ||
                (critter.familySpecies?.lowercased().contains(lowercased) ?? false) ||
                critter.memberType.lowercased().contains(lowercased) ||
                (critter.role?.lowercased().contains(lowercased) ?? false)
            }
        }
        
        return critters
    }
    
    private var groupedCritters: [String: [Critter]] {
        Dictionary(grouping: filteredCritters) { critter in
            critter.familyName ?? "Unknown Family"
        }
    }
    
    private var sortedFamilyNames: [String] {
        groupedCritters.keys.sorted()
    }
    
    private var availableFamilies: [String] {
        let families = Set(allCritters.compactMap { $0.familyName })
        return families.sorted()
    }
    
    private var availableMemberTypes: [String] {
        let types = Set(allCritters.map { $0.memberType })
        return types.sorted()
    }
    
    // Optimization: Create lookup dictionary for owned variants by critter UUID
    private var ownedVariantsByCritter: [String: [OwnedVariant]] {
        Dictionary(grouping: ownedVariants) { $0.critterUuid }
    }
    
    private func ownedVariantsFor(_ critter: Critter) -> [OwnedVariant] {
        ownedVariantsByCritter[critter.uuid] ?? []
    }
    
    // MARK: - Actions
    
    private func handleCollectionAction(for critter: Critter) {
        if critter.variantsCount == 0 {
            ToastManager.shared.show("This critter has no variants", type: .error)
            return
        }
        
        if critter.variantsCount == 1 {
            addSingleVariant(critter: critter, status: .collection)
        } else {
            pickerTargetStatus = .collection
            selectedCritter = critter
        }
    }
    
    private func handleWishlistAction(for critter: Critter) {
        if critter.variantsCount == 0 {
            ToastManager.shared.show("This critter has no variants", type: .error)
            return
        }
        
        if critter.variantsCount == 1 {
            addSingleVariant(critter: critter, status: .wishlist)
        } else {
            pickerTargetStatus = .wishlist
            selectedCritter = critter
        }
    }
    
    private func addSingleVariant(critter: Critter, status: CritterStatus) {
        let critterVariants = allVariants.filter { $0.critterId == critter.uuid }
        
        guard let variant = critterVariants.first else {
            ToastManager.shared.show("Variant not found", type: .error)
            return
        }
        
        let alreadyOwned = ownedVariants.contains {
            $0.variantUuid == variant.uuid && $0.status == status
        }
        
        if alreadyOwned {
            try? OwnedVariant.remove(variantUuid: variant.uuid, in: modelContext)
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            
            ToastManager.shared.show(
                "Removed \(variant.name) from \(status == .collection ? "Collection" : "Wishlist")",
                type: .info
            )
        } else {
            try? OwnedVariant.create(
                variant: variant,
                critter: critter,
                status: status,
                in: modelContext
            )
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            ToastManager.shared.show(
                "✓ Added \(variant.name) to \(status == .collection ? "Collection" : "Wishlist")",
                type: .success
            )
        }
    }
    
    // MARK: - Barcode Scanner
    
    private func fetchScannedSet(_ barcode: String) async {
        isLoadingSet = true
        showingBarcodeScanner = false
        
        do {
            let setResponse = try await SetService.shared.fetchSetByBarcode(barcode)
            scannedSet = setResponse
            isLoadingSet = false
            showingScannedSetPicker = true
            
            // Clear scanned barcode for next scan
            scannedBarcode = nil
        } catch {
            isLoadingSet = false
            
            let errorMessage: String
            if let setError = error as? SetServiceError {
                errorMessage = setError.localizedDescription
            } else {
                errorMessage = "Failed to load set"
            }
            
            ToastManager.shared.show(errorMessage, type: .error)
            
            // Clear scanned barcode
            scannedBarcode = nil
        }
    }
}

// MARK: - Filter Chips View
struct FilterChipsView: View {
    @Binding var selectedFamily: String?
    @Binding var selectedMemberType: String?
    let availableFamilies: [String]
    let availableMemberTypes: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Family filter
                Menu {
                    Button("All Families") {
                        selectedFamily = nil
                    }
                    
                    Divider()
                    
                    ForEach(availableFamilies, id: \.self) { family in
                        Button(family) {
                            selectedFamily = family
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.caption)
                        Text(selectedFamily ?? "All Families")
                            .font(.subheadline)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(selectedFamily != nil ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(selectedFamily != nil ? .white : .primary)
                    .clipShape(Capsule())
                }
                
                // Member type filter
                Menu {
                    Button("All Types") {
                        selectedMemberType = nil
                    }
                    
                    Divider()
                    
                    ForEach(availableMemberTypes, id: \.self) { type in
                        Button(type) {
                            selectedMemberType = type
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "person.3")
                            .font(.caption)
                        Text(selectedMemberType ?? "All Types")
                            .font(.subheadline)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(selectedMemberType != nil ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(selectedMemberType != nil ? .white : .primary)
                    .clipShape(Capsule())
                }
                
                // Clear filters button (only show if any filter is active)
                if selectedFamily != nil || selectedMemberType != nil {
                    Button {
                        selectedFamily = nil
                        selectedMemberType = nil
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                            Text("Clear")
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.calicoError)
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

// MARK: - Critter Row
struct CritterRow: View {
    let critter: Critter
    let ownedVariants: [OwnedVariant]
    
    @Query private var allVariants: [CritterVariant]
    
    private var critterVariants: [CritterVariant] {
        allVariants.filter { $0.critterId == critter.uuid }
    }
    
    private var hasInCollection: Bool {
        ownedVariants.contains { $0.status == .collection }
    }
    
    private var hasInWishlist: Bool {
        ownedVariants.contains { $0.status == .wishlist }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            StackedVariantImages(variants: critterVariants)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(critter.name)
                    .font(.headline)
                
                HStack(spacing: 4) {
//                    if let familyName = critter.familyName {
//                        Text(familyName)
//                    }
                    if let role = critter.role, !role.isEmpty {
//                        Text("•")
                        Text(role)
                    }
                }
                .font(.subheadline)
                .foregroundColor(.calicoTextSecondary)
                
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

// MARK: - Stacked Variant Images
struct StackedVariantImages: View {
    let variants: [CritterVariant]
    private let imageSize: CGFloat = 60
    private let stackOffset: CGFloat = 8
    
    var body: some View {
        ZStack(alignment: .leading) {
            if variants.isEmpty || variants.allSatisfy({ $0.thumbnailURL == nil && $0.imageURL == nil }) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: imageSize, height: imageSize)
                    .overlay {
                        Image(systemName: "pawprint.fill")
                            .foregroundColor(.gray)
                    }
            } else {
                // Use primary variant first, then up to 2 total
                let primaryVariant = variants.primaryOrFirst()
                let displayVariants = [primaryVariant].compactMap { $0 } +
                    variants.filter { $0.uuid != primaryVariant?.uuid }.prefix(1)
                
                ForEach(Array(displayVariants.enumerated()), id: \.element.uuid) { index, variant in
                    if let urlString = variant.thumbnailURL ?? variant.imageURL {
                        CachedAsyncImage(url: urlString) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: imageSize, height: imageSize)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white, lineWidth: 2.5)
                                )
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: imageSize, height: imageSize)
                                .overlay { ProgressView() }
                        }
                        .offset(x: CGFloat(index) * stackOffset)
                        .zIndex(Double(displayVariants.count - index))
                    }
                }
            }
        }
        .frame(width: imageSize + (CGFloat(min(variants.count, 2) - 1) * stackOffset), height: imageSize)
    }
}

#Preview {
    NavigationStack {
        SearchView(searchText: .constant(""))
            .modelContainer(for: OwnedVariant.self, inMemory: true)
            .environmentObject(SyncService.shared)
    }
}
