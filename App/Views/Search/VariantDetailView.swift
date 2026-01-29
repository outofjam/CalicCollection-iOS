//
//  VariantDetailView.swift
//  LottaPaws
//
//  Detail view for variants from the API/browse.
//  For owned variants, see OwnedVariantDetailView.
//

import SwiftUI
import SwiftData

struct VariantDetailView: View {
    let variant: VariantResponse
    let critter: CritterInfo
    let familyUuid: String
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var ownedVariants: [OwnedVariant]
    @ObservedObject private var appSettings = AppSettings.shared
    
    @State private var showingFullscreenImage = false
    @State private var showingPurchaseDetails = false
    @State private var showingReportIssue = false
    @State private var isAdding = false
    
    private var ownedVariant: OwnedVariant? {
        ownedVariants.first { $0.variantUuid == variant.uuid }
    }
    
    private var isInCollection: Bool {
        ownedVariant?.status == .collection
    }
    
    private var isInWishlist: Bool {
        ownedVariant?.status == .wishlist
    }
    
    private var hasPurchaseDetails: Bool {
        guard let owned = ownedVariant else { return false }
        return owned.pricePaid != nil || owned.purchaseDate != nil ||
               owned.purchaseLocation != nil || owned.condition != nil || owned.notes != nil
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // MARK: - Hero Image
                    VariantHeroImage(
                        variant: variant,
                        critter: critter,
                        onExpandTap: { showingFullscreenImage = true }
                    )
                    
                    // MARK: - Content
                    VStack(spacing: LottaPawsTheme.spacingXL) {
                        // Photo Gallery (only for collection items)
                        if isInCollection {
                            PhotoGallerySection(variantUuid: variant.uuid)
                                .padding(.vertical, LottaPawsTheme.spacingSM)
                        }
                        
                        // Status Badge
                        if let owned = ownedVariant, let status = owned.status {
                            VariantStatusBadge(status: status, addedDate: owned.addedDate)
                        }
                        
                        // Info Section
                        infoSection
                        
                        // Purchase Details Section
                        if appSettings.showPurchaseDetails,
                           let owned = ownedVariant,
                           owned.status == .collection {
                            PurchaseDetailsSection(
                                ownedVariant: owned,
                                hasPurchaseDetails: hasPurchaseDetails,
                                showingPurchaseDetails: $showingPurchaseDetails,
                                modelContext: modelContext
                            )
                        }
                        
                        // Extra bottom padding for sticky action bar
                        Color.clear.frame(height: 80)
                    }
                    .padding(.horizontal, LottaPawsTheme.spacingLG)
                    .padding(.top, LottaPawsTheme.spacingXL)
                }
            }
            .background(Color.backgroundPrimary)
            .ignoresSafeArea(edges: .top)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .safeAreaInset(edge: .bottom) {
                BottomActionBar(
                    isInCollection: isInCollection,
                    isInWishlist: isInWishlist,
                    variantName: variant.name,
                    onAddToCollection: { Task { await addToCollection() } },
                    onAddToWishlist: { Task { await addToWishlist() } },
                    onMoveToWishlist: { Task { await moveToWishlist() } },
                    onRemove: removeVariant
                )
            }
            .fullScreenCover(isPresented: $showingFullscreenImage) {
                if let imageURL = variant.imageUrl {
                    FullscreenImageViewer(imageURL: imageURL)
                }
            }
            .sheet(isPresented: $showingPurchaseDetails) {
                if let owned = ownedVariant {
                    PurchaseDetailsSheet(ownedVariant: owned)
                }
            }
            .sheet(isPresented: $showingReportIssue) {
                ReportIssueSheet(variantUuid: variant.uuid, variantName: variant.name)
            }
            .overlay { loadingOverlay }
        }
        .toast()
    }
    
    // MARK: - Subviews
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: LottaPawsTheme.spacingMD) {
            if let familyName = critter.familyName {
                InfoRow(label: "Family", value: familyName)
            }
            
            InfoRow(label: "Member Type", value: critter.memberType.capitalized)
            
            if let sku = variant.sku {
                InfoRow(label: "SKU", value: sku)
            }
            
            if let barcode = variant.barcode {
                InfoRow(label: "Barcode", value: barcode)
            }
            
            if let releaseYear = variant.releaseYear {
                InfoRow(label: "Release Year", value: String(releaseYear))
            }
            
            if let notes = variant.notes {
                VStack(alignment: .leading, spacing: LottaPawsTheme.spacingXS) {
                    Text("Notes")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Text(notes)
                        .font(.body)
                        .foregroundColor(.textPrimary)
                }
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Done") { dismiss() }
                .foregroundColor(.primaryPink)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    showingReportIssue = true
                } label: {
                    Label("Report Issue", systemImage: "flag")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.primaryPink)
            }
        }
    }
    
    @ViewBuilder
    private var loadingOverlay: some View {
        if isAdding {
            ZStack {
                Color.black.opacity(0.3)
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.primaryPink)
            }
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Actions
    
    private func addToCollection() async {
        isAdding = true
        defer { isAdding = false }
        
        do {
            try await OwnedVariant.create(
                variant: variant,
                critter: critter,
                familyId: familyUuid,
                status: .collection,
                in: modelContext
            )
            
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            
            if AppSettings.shared.showConfetti {
                ConfettiManager.shared.trigger()
            }
            
            ToastManager.shared.show("✓ Added \(variant.name) to Collection", type: .success)
        } catch {
            ToastManager.shared.show("Failed to add", type: .error)
        }
    }
    
    private func addToWishlist() async {
        isAdding = true
        defer { isAdding = false }
        
        do {
            try await OwnedVariant.create(
                variant: variant,
                critter: critter,
                familyId: familyUuid,
                status: .wishlist,
                in: modelContext
            )
            
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            ToastManager.shared.show("✓ Added \(variant.name) to Wishlist", type: .success)
        } catch {
            ToastManager.shared.show("Failed to add", type: .error)
        }
    }
    
    private func moveToWishlist() async {
        isAdding = true
        defer { isAdding = false }
        
        do {
            try await OwnedVariant.create(
                variant: variant,
                critter: critter,
                familyId: familyUuid,
                status: .wishlist,
                in: modelContext
            )
            
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            ToastManager.shared.show("✓ Moved \(variant.name) to Wishlist", type: .success)
        } catch {
            ToastManager.shared.show("Failed to move", type: .error)
        }
    }
    
    private func removeVariant() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        try? OwnedVariant.remove(variantUuid: variant.uuid, in: modelContext)
        ToastManager.shared.show("Removed \(variant.name)", type: .info)
        dismiss()
    }
}

#Preview {
    VariantDetailView(
        variant: VariantResponse(
            uuid: "1",
            critterId: "1",
            name: "Royal Princess Set",
            sku: "CC-1234",
            barcode: "123456789",
            imageUrl: nil,
            thumbnailUrl: nil,
            releaseYear: 2023,
            notes: "Limited edition",
            setId: nil,
            setName: nil,
            epochId: nil,
            createdAt: "",
            updatedAt: "",
            isPrimary: true
        ),
        critter: CritterInfo(
            uuid: "1",
            name: "Bruce Husky",
            memberType: "kids",
            familyName: "Husky Family",
            familyUuid: "de7237f6-7f2e-4dc1-959b-a5dc02bb677c"
        ),
        familyUuid: "family-1"
    )
}
