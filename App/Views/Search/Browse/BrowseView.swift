//
//  BrowseView.swift
//  LottaPaws
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
    @State private var searchResults: [CritterSearchResult] = []
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
            Group {
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                familyFilterMenu
            }
        }
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
    
    // MARK: - Family Filter Menu
    
    private var familyFilterMenu: some View {
        Menu {
            Button {
                selectedFamilyUuid = nil
                selectedFamilyName = nil
            } label: {
                HStack {
                    Text("All Families")
                    if selectedFamilyUuid == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            Divider()
            
            ForEach(cachedFamilies.sorted(by: { $0.name < $1.name })) { family in
                Button {
                    selectedFamilyUuid = family.uuid
                    selectedFamilyName = family.name
                } label: {
                    HStack {
                        Text(family.name)
                        if selectedFamilyUuid == family.uuid {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: selectedFamilyUuid != nil ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                if let name = selectedFamilyName {
                    Text(name)
                        .font(.subheadline)
                        .lineLimit(1)
                }
            }
            .foregroundColor(.primaryPink)
        }
    }
    
    // MARK: - Browse Content
    
    private var browseContent: some View {
        BrowseCrittersList(
            critters: browseCritters,
            isLoading: isLoadingBrowse,
            error: browseError,
            currentPage: currentPage,
            totalPages: totalPages,
            onLoadMore: { Task { await loadBrowseCritters(reset: false) } },
            onRetry: { Task { await loadBrowseCritters(reset: true) } },
            onCollectionAction: handleCollectionAction,
            onWishlistAction: handleWishlistAction,
            collectionCountFor: collectionCountFor,
            wishlistCountFor: wishlistCountFor
        )
    }
    
    // MARK: - Search Content
    
    private var searchContent: some View {
        SearchResultsList(
            results: searchResults,
            searchText: searchText,
            isSearching: isSearching,
            error: searchError,
            currentPage: searchPage,
            totalPages: searchTotalPages,
            onLoadMore: { Task { await performSearch(reset: false) } },
            onCritterTap: { result in
                handleSearchCritterTap(result)
            },
            collectionCountFor: collectionCountFor,
            wishlistCountFor: wishlistCountFor
        )
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
                    .fill(Color.primaryPink)
                    .frame(width: 60, height: 60)
                    .shadow(
                        color: LottaPawsTheme.shadowMedium.color,
                        radius: LottaPawsTheme.shadowMedium.radius,
                        x: LottaPawsTheme.shadowMedium.x,
                        y: LottaPawsTheme.shadowMedium.y
                    )
                
                Image(systemName: "barcode.viewfinder")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
        }
        .padding(LottaPawsTheme.spacingLG)
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: LottaPawsTheme.spacingMD) {
                ProgressView()
                    .tint(.primaryPink)
                    .scaleEffect(1.5)
                Text(isAddingSingleVariant ? "Adding..." : "Loading set...")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
            .padding(LottaPawsTheme.spacingXL)
            .background(Color.backgroundPrimary)
            .cornerRadius(LottaPawsTheme.radiusMD)
            .shadow(
                color: LottaPawsTheme.shadowMedium.color,
                radius: LottaPawsTheme.shadowMedium.radius,
                x: LottaPawsTheme.shadowMedium.x,
                y: LottaPawsTheme.shadowMedium.y
            )
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
        } catch is CancellationError {
            // Don't treat cancellation as an error
            AppLogger.debug("Browse fetch cancelled")
            if reset { currentPage = 1 }
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
                perPage: 20
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
    
    private func collectionCountFor(_ critterUuid: String) -> Int {
        ownedVariants.filter { $0.critterUuid == critterUuid && $0.status == .collection }.count
    }
    
    private func wishlistCountFor(_ critterUuid: String) -> Int {
        ownedVariants.filter { $0.critterUuid == critterUuid && $0.status == .wishlist }.count
    }
    
    private func handleCollectionAction(for critter: BrowseCritterResponse) {
        if critter.variantsCount == 0 {
            ToastManager.shared.show("This critter has no variants", type: .error)
            return
        }
        
        // Single variant - add directly without picker
        if critter.variantsCount == 1 {
            Task { await handleSingleVariantAdd(critterUuid: critter.uuid, status: .collection) }
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
            Task { await handleSingleVariantAdd(critterUuid: critter.uuid, status: .wishlist) }
            return
        }
        
        // Multiple variants - show picker
        pickerTargetStatus = .wishlist
        selectedCritterUuid = critter.uuid
    }
    
    private func handleSingleVariantAdd(critterUuid: String, status: CritterStatus) async {
        isAddingSingleVariant = true
        defer { isAddingSingleVariant = false }
        
        do {
            try await VariantAdditionHelpers.addSingleVariant(
                critterUuid: critterUuid,
                status: status,
                modelContext: modelContext,
                ownedVariants: ownedVariants
            )
            
            ToastManager.shared.show(
                "✓ Added to \(status == .collection ? "Collection" : "Wishlist")",
                type: .success
            )
        } catch let error as VariantAdditionError {
            ToastManager.shared.show(error.localizedDescription, type: .info)
        } catch {
            AppLogger.error("Failed to add single variant: \(error)")
            ToastManager.shared.show("Failed to add variant", type: .error)
        }
    }
    
    private func handleSearchCritterTap(_ result: CritterSearchResult) {
        // If only one matching variant, could add directly
        // For now, always show picker for consistency
        pickerTargetStatus = .collection
        selectedCritterUuid = result.critterUuid
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
