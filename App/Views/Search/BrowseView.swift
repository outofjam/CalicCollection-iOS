//
//  BrowseView.swift
//  CalicCollectionV2
//
//  Created by Ismail Dawoodjee on 2026-01-28.
//


import SwiftUI
import SwiftData

struct BrowseView: View {
    @Binding var searchText: String
    @Environment(\.modelContext) private var modelContext
    
    @Query private var ownedVariants: [OwnedVariant]
    @Query private var cachedFamilies: [Family]
    
    // Browse state
    @State private var browseCritters: [BrowseCritterResponse] = []
    @State private var currentPage = 1
    @State private var totalPages = 1
    @State private var isLoadingBrowse = false
    @State private var browseError: String?
    
    // Search state
    @State private var searchResults: [SearchResultResponse] = []
    @State private var searchPage = 1
    @State private var searchTotalPages = 1
    @State private var isSearching = false
    @State private var searchError: String?
    @State private var searchTask: Task<Void, Never>?
    
    // Filters
    @State private var selectedFamilyUuid: String? = nil
    @State private var selectedFamilyName: String? = nil
    
    // Variant picker
    @State private var selectedCritterUuid: String?
    @State private var pickerTargetStatus: CritterStatus = .collection
    
    // Single variant add
    @State private var isAddingSingleVariant = false
    
    // Barcode scanner
    @State private var showingBarcodeScanner = false
    @State private var scannedBarcode: String?
    @State private var scannedSet: SetResponse?
    @State private var showingScannedSetPicker = false
    @State private var isLoadingSet = false
    
    private var isSearchMode: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty && searchText.count >= 2
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if !isSearchMode {
                    FilterChipsView(
                        selectedFamilyUuid: $selectedFamilyUuid,
                        selectedFamilyName: $selectedFamilyName,
                        families: cachedFamilies
                    )
                }
                
                if isSearchMode {
                    searchContent
                } else {
                    browseContent
                }
            }
            
            // Floating barcode button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    barcodeScanButton
                }
            }
        }
        .navigationTitle("Browse")
        .searchable(text: $searchText, prompt: "Search critters & variants...")
        .onChange(of: searchText) { _, newValue in
            handleSearchTextChange(newValue)
        }
        .onChange(of: selectedFamilyUuid) { _, _ in
            Task { await loadBrowseCritters(reset: true) }
        }
        .task {
            await loadBrowseCritters(reset: true)
        }
        .sheet(isPresented: Binding(
            get: { selectedCritterUuid != nil },
            set: { if !$0 { selectedCritterUuid = nil } }
        )) {
            if let critterUuid = selectedCritterUuid {
                VariantPickerSheet(
                    critterUuid: critterUuid,
                    targetStatus: pickerTargetStatus
                )
            }
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
        .onChange(of: scannedBarcode) { _, newValue in
            if let barcode = newValue {
                Task { await fetchScannedSet(barcode) }
            }
        }
        .overlay {
            if isLoadingSet || isAddingSingleVariant { loadingOverlay }
        }
    }
    
    // MARK: - Browse Content
    
    @ViewBuilder
    private var browseContent: some View {
        if isLoadingBrowse && browseCritters.isEmpty {
            ProgressView("Loading critters...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = browseError, browseCritters.isEmpty {
            ContentUnavailableView {
                Label("Error", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error)
            } actions: {
                Button("Retry") {
                    Task { await loadBrowseCritters(reset: true) }
                }
            }
        } else if browseCritters.isEmpty {
            ContentUnavailableView(
                "No Critters",
                systemImage: "pawprint.fill",
                description: Text("No critters found")
            )
        } else {
            List {
                ForEach(browseCritters) { critter in
                    NavigationLink {
                        CritterDetailView(critterUuid: critter.uuid)
                    } label: {
                        BrowseCritterRow(
                            critter: critter,
                            ownedCount: ownedCountFor(critter.uuid)
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
                    .onAppear {
                        if critter.id == browseCritters.last?.id && currentPage < totalPages {
                            Task { await loadBrowseCritters(reset: false) }
                        }
                    }
                }
                
                if isLoadingBrowse && !browseCritters.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.insetGrouped)
            .refreshable {
                await loadBrowseCritters(reset: true)
            }
        }
    }
    
    // MARK: - Search Content
    
    @ViewBuilder
    private var searchContent: some View {
        if isSearching && searchResults.isEmpty {
            ProgressView("Searching...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = searchError, searchResults.isEmpty {
            ContentUnavailableView {
                Label("Search Error", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error)
            }
        } else if searchResults.isEmpty && !searchText.isEmpty {
            ContentUnavailableView(
                "No Results",
                systemImage: "magnifyingglass",
                description: Text("No variants found for \"\(searchText)\"")
            )
        } else {
            List {
                ForEach(searchResults) { result in
                    SearchResultRow(
                        result: result,
                        isOwned: isOwned(result.variantUuid)
                    )
                    .swipeActions(edge: .leading) {
                        Button {
                            Task { await addSearchResult(result, status: .collection) }
                        } label: {
                            Label("Collection", systemImage: "star.fill")
                        }
                        .tint(.calicoPrimary)
                    }
                    .swipeActions(edge: .trailing) {
                        Button {
                            Task { await addSearchResult(result, status: .wishlist) }
                        } label: {
                            Label("Wishlist", systemImage: "heart.fill")
                        }
                        .tint(.calicoSecondary)
                    }
                    .onAppear {
                        if result.id == searchResults.last?.id && searchPage < searchTotalPages {
                            Task { await performSearch(reset: false) }
                        }
                    }
                }
                
                if isSearching && !searchResults.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.insetGrouped)
        }
    }
    
    // MARK: - Subviews
    
    private var barcodeScanButton: some View {
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
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.5)
                Text(isAddingSingleVariant ? "Adding..." : "Loading set...")
                    .font(.subheadline)
            }
            .padding(20)
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Data Loading
    
    private func loadBrowseCritters(reset: Bool) async {
        if reset {
            currentPage = 1
            browseCritters = []
        } else {
            currentPage += 1
        }
        
        isLoadingBrowse = true
        browseError = nil
        
        do {
            let response = try await BrowseService.shared.fetchCritters(
                page: currentPage,
                perPage: 30,
                familyUuid: selectedFamilyUuid
            )
            
            if reset {
                browseCritters = response.data
            } else {
                browseCritters.append(contentsOf: response.data)
            }
            
            totalPages = response.meta.lastPage
        } catch {
            browseError = error.localizedDescription
            if reset { currentPage = 1 }
        }
        
        isLoadingBrowse = false
    }
    
    private func handleSearchTextChange(_ newValue: String) {
        searchTask?.cancel()
        
        let trimmed = newValue.trimmingCharacters(in: .whitespaces)
        
        if trimmed.count < 2 {
            searchResults = []
            searchError = nil
            return
        }
        
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            if !Task.isCancelled {
                await performSearch(reset: true)
            }
        }
    }
    
    private func performSearch(reset: Bool) async {
        if reset {
            searchPage = 1
            searchResults = []
        } else {
            searchPage += 1
        }
        
        isSearching = true
        searchError = nil
        
        do {
            let response = try await SearchService.shared.search(
                query: searchText,
                page: searchPage,
                perPage: 30
            )
            
            if reset {
                searchResults = response.data
            } else {
                searchResults.append(contentsOf: response.data)
            }
            
            searchTotalPages = response.meta.lastPage
        } catch {
            if !Task.isCancelled {
                searchError = error.localizedDescription
            }
        }
        
        isSearching = false
    }
    
    // MARK: - Actions
    
    private func ownedCountFor(_ critterUuid: String) -> Int {
        ownedVariants.filter { $0.critterUuid == critterUuid }.count
    }
    
    private func isOwned(_ variantUuid: String) -> Bool {
        ownedVariants.contains { $0.variantUuid == variantUuid }
    }
    
    private func handleCollectionAction(for critter: BrowseCritterResponse) {
        if critter.variantsCount == 0 {
            ToastManager.shared.show("This critter has no variants", type: .error)
            return
        }
        
        // Single variant - add directly without picker
        if critter.variantsCount == 1 {
            Task { await addSingleVariant(critterUuid: critter.uuid, status: .collection) }
            return
        }
        
        // Multiple variants - show picker
        pickerTargetStatus = .collection
        selectedCritterUuid = critter.uuid
    }
    
    private func handleWishlistAction(for critter: BrowseCritterResponse) {
        if critter.variantsCount == 0 {
            ToastManager.shared.show("This critter has no variants", type: .error)
            return
        }
        
        // Single variant - add directly without picker
        if critter.variantsCount == 1 {
            Task { await addSingleVariant(critterUuid: critter.uuid, status: .wishlist) }
            return
        }
        
        // Multiple variants - show picker
        pickerTargetStatus = .wishlist
        selectedCritterUuid = critter.uuid
    }
    
    private func addSingleVariant(critterUuid: String, status: CritterStatus) async {
        isAddingSingleVariant = true
        defer { isAddingSingleVariant = false }
        
        do {
            let response = try await BrowseService.shared.fetchCritterVariants(critterUuid: critterUuid)
            
            guard let variant = response.variants.first else {
                ToastManager.shared.show("No variant found", type: .error)
                return
            }
            
            // Check if already owned
            if ownedVariants.contains(where: { $0.variantUuid == variant.uuid }) {
                ToastManager.shared.show("Already in your \(status == .collection ? "collection" : "wishlist")", type: .info)
                return
            }
            
            // Create OwnedVariant
            let owned = OwnedVariant(
                variantUuid: variant.uuid,
                critterUuid: response.critter.uuid,
                critterName: response.critter.name,
                variantName: variant.name,
                familyId: response.critter.familyUuid ?? "",
                familyName: response.critter.familyName,
                familySpecies: nil,
                memberType: response.critter.memberType,
                role: nil,
                imageURL: variant.imageUrl,
                thumbnailURL: variant.thumbnailUrl,
                status: status
            )
            
            modelContext.insert(owned)
            try modelContext.save()
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            ToastManager.shared.show(
                "✓ Added to \(status == .collection ? "Collection" : "Wishlist")",
                type: .success
            )
        } catch {
            AppLogger.error("Failed to add single variant: \(error)")
            ToastManager.shared.show("Failed to add variant", type: .error)
        }
    }
    
    private func addSearchResult(_ result: SearchResultResponse, status: CritterStatus) async {
        do {
            try await OwnedVariant.create(from: result, status: status, in: modelContext)
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            ToastManager.shared.show(
                "✓ Added to \(status == .collection ? "Collection" : "Wishlist")",
                type: .success
            )
        } catch {
            ToastManager.shared.show("Failed to add", type: .error)
        }
    }
    
    private func fetchScannedSet(_ barcode: String) async {
        isLoadingSet = true
        showingBarcodeScanner = false
        
        do {
            let setResponse = try await SetService.shared.fetchSetByBarcode(barcode)
            scannedSet = setResponse
            isLoadingSet = false
            showingScannedSetPicker = true
            scannedBarcode = nil
        } catch {
            isLoadingSet = false
            
            let errorMessage: String
            if let apiError = error as? APIError {
                errorMessage = apiError.localizedDescription
            } else {
                errorMessage = "Failed to load set"
            }
            
            ToastManager.shared.show(errorMessage, type: .error)
            scannedBarcode = nil
        }
    }
}

// MARK: - Typealias for backwards compatibility
typealias SearchView = BrowseView

#Preview {
    NavigationStack {
        BrowseView(searchText: .constant(""))
    }
}
