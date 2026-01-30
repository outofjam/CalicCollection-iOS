//
//  OwnedVariantsView.swift
//  LottaPaws
//
//  Displays user's collection or wishlist with list/gallery/stats views.
//

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
    
    private var groupedVariants: [String: [OwnedVariant]] {
        Dictionary(grouping: filteredVariants) { variant in
            variant.familyName ?? "Unknown Family"
        }
    }
    
    private var sortedFamilyNames: [String] {
        groupedVariants.keys.sorted()
    }
    
    private var iconForMode: String {
        switch viewMode {
        case .list:
            return "square.grid.2x2"
        case .gallery:
            return status == .collection ? "chart.bar" : "list.bullet"
        case .stats:
            return "list.bullet"
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if filteredVariants.isEmpty {
                    LPEmptyState(
                        icon: emptyIcon,
                        title: "No \(title) Yet",
                        message: emptyDescription
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
                        withAnimation(LottaPawsTheme.animationSpring) {
                            cycleViewMode()
                        }
                    } label: {
                        Image(systemName: iconForMode)
                            .foregroundColor(.primaryPink)
                    }
                }
            }
            .sheet(item: $selectedVariant) { variant in
                OwnedVariantDetailView(ownedVariant: variant)
            }
        }
    }
    
    private func cycleViewMode() {
        if status == .collection {
            // Collection has 3 modes: list → gallery → stats → list
            switch viewMode {
            case .list: viewMode = .gallery
            case .gallery: viewMode = .stats
            case .stats: viewMode = .list
            }
        } else {
            // Wishlist has 2 modes: list → gallery → list
            viewMode = viewMode == .list ? .gallery : .list
        }
    }
}

// MARK: - Owned Variant Detail View

/// Detail view for owned variants - works offline with stored data
struct OwnedVariantDetailView: View {
    let ownedVariant: OwnedVariant
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var appSettings = AppSettings.shared
    
    @State private var showingFullscreenImage = false
    @State private var showingPurchaseDetails = false
    @State private var showingReportIssue = false
    @State private var showingCritterDetail = false
    
    private var hasPurchaseDetails: Bool {
        ownedVariant.pricePaid != nil ||
        ownedVariant.purchaseDate != nil ||
        ownedVariant.purchaseLocation != nil ||
        ownedVariant.condition != nil ||
        ownedVariant.notes != nil
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // MARK: - Hero Image
                    VariantHeroImage(
                        ownedVariant: ownedVariant,
                        onExpandTap: { showingFullscreenImage = true }
                    )
                    
                    // MARK: - Content
                    VStack(spacing: LottaPawsTheme.spacingXL) {
                        // Photo Gallery (collection items only)
                        if ownedVariant.status == .collection {
                            PhotoGallerySection(variantUuid: ownedVariant.variantUuid)
                                .padding(.vertical, LottaPawsTheme.spacingSM)
                        }
                        
                        // Status Badge
//                        if let status = ownedVariant.status {
//                            VariantStatusBadge(
//                                status: status,
//                                addedDate: ownedVariant.addedDate
//                            )
//                        }
                        
                        // Info Card (details + view critter)
                        infoCard
                        
                        // Purchase Details (collection only)
                        if appSettings.showPurchaseDetails && ownedVariant.status == .collection {
                            PurchaseDetailsSection(
                                ownedVariant: ownedVariant,
                                hasPurchaseDetails: hasPurchaseDetails,
                                showingPurchaseDetails: $showingPurchaseDetails,
                                modelContext: modelContext
                            )
                        }
                        
                        // Extra padding for bottom action bar
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
                OwnedVariantActionBar(
                    ownedVariant: ownedVariant,
                    onRemove: removeVariant,
                    onMoveToWishlist: moveToWishlist,
                    onMoveToCollection: moveToCollection
                )
            }
            .fullScreenCover(isPresented: $showingFullscreenImage) {
                FullscreenImageViewer(ownedVariant: ownedVariant)
            }
            .sheet(isPresented: $showingPurchaseDetails) {
                PurchaseDetailsSheet(ownedVariant: ownedVariant)
            }
            .sheet(isPresented: $showingReportIssue) {
                ReportIssueSheet(
                    variantUuid: ownedVariant.variantUuid,
                    variantName: ownedVariant.variantName
                )
            }
            .navigationDestination(isPresented: $showingCritterDetail) {
                CritterDetailView(critterUuid: ownedVariant.critterUuid)
            }
        }
        .toast()
    }
    
    // MARK: - Subviews
    
    private var infoCard: some View {
        VStack(spacing: 0) {
            // Info rows
            VStack(alignment: .leading, spacing: LottaPawsTheme.spacingMD) {
                if let familyName = ownedVariant.familyName {
                    InfoRow(label: "Family", value: familyName)
                }
                
                InfoRow(label: "Member Type", value: ownedVariant.memberType.capitalized)
                
                if let role = ownedVariant.role {
                    InfoRow(label: "Role", value: role)
                }
                
                if let birthday = ownedVariant.formattedBirthday {
                    InfoRow(label: "Birthday", value: birthday)
                }
                
                if let setName = ownedVariant.setName, let epochId = ownedVariant.epochId {
                    InfoRow(label: "Set", value: "\(setName) (\(epochId))")
                } else if let setName = ownedVariant.setName {
                    InfoRow(label: "Set", value: setName)
                } else if let epochId = ownedVariant.epochId {
                    InfoRow(label: "Set ID", value: epochId)
                }
        
                // Status with date
                if let status = ownedVariant.status {
                    InfoRow(
                        label: status == .collection ? "In Collection" : "In Wishlist",
                        value: ownedVariant.addedDate.formatted(date: .abbreviated, time: .omitted)
                    )
                }
            }
            .padding(LottaPawsTheme.spacingMD)
            
            // Divider
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 1)
            
            // View Critter button
            Button {
                showingCritterDetail = true
            } label: {
                HStack {
                    Image(systemName: "pawprint.fill")
                        .font(.subheadline)
                    Text("View Critter")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                }
                .font(.subheadline.weight(.medium))
                .foregroundColor(.primaryPink)
                .padding(LottaPawsTheme.spacingMD)
            }
        }
        .background(Color.backgroundSecondary)
        .cornerRadius(LottaPawsTheme.radiusMD)
        .overlay(
            RoundedRectangle(cornerRadius: LottaPawsTheme.radiusMD)
                .stroke(Color(.separator).opacity(0.5), lineWidth: 1)
        )
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
    
    // MARK: - Actions
    
    private func removeVariant() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        try? OwnedVariant.remove(variantUuid: ownedVariant.variantUuid, in: modelContext)
        ToastManager.shared.show("Removed \(ownedVariant.variantName)", type: .info)
        dismiss()
    }
    
    private func moveToWishlist() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        ownedVariant.status = .wishlist
        try? modelContext.save()
        ToastManager.shared.show("✓ Moved to Wishlist", type: .success)
    }
    
    private func moveToCollection() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        ownedVariant.status = .collection
        ownedVariant.addedDate = Date()
        try? modelContext.save()
        ToastManager.shared.show("✓ Moved to Collection", type: .success)
    }
}

// MARK: - Owned Variant Action Bar

struct OwnedVariantActionBar: View {
    let ownedVariant: OwnedVariant
    let onRemove: () -> Void
    let onMoveToWishlist: () -> Void
    let onMoveToCollection: () -> Void
    
    var body: some View {
        HStack(spacing: LottaPawsTheme.spacingMD) {
            if ownedVariant.status == .collection {
                moveToWishlistButton
            } else {
                moveToCollectionButton
            }
            
            removeButton
        }
        .padding(LottaPawsTheme.spacingLG)
        .background(.ultraThinMaterial)
    }
    
    private var moveToWishlistButton: some View {
        Button(action: onMoveToWishlist) {
            HStack {
                Image(systemName: "heart")
                Text("Move to Wishlist")
            }
            .font(.subheadline.weight(.medium))
            .foregroundColor(.primaryPink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, LottaPawsTheme.spacingMD)
            .background(Color.primaryPinkLight.opacity(0.5))
            .cornerRadius(LottaPawsTheme.radiusSM)
        }
    }
    
    private var moveToCollectionButton: some View {
        Button(action: onMoveToCollection) {
            HStack {
                Image(systemName: "star")
                Text("Move to Collection")
            }
            .font(.subheadline.weight(.medium))
            .foregroundColor(.secondaryBlue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, LottaPawsTheme.spacingMD)
            .background(Color.secondaryBlueLight.opacity(0.5))
            .cornerRadius(LottaPawsTheme.radiusSM)
        }
    }
    
    private var removeButton: some View {
        Button(action: onRemove) {
            Image(systemName: "trash")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.errorRed)
                .padding(.vertical, LottaPawsTheme.spacingMD)
                .padding(.horizontal, LottaPawsTheme.spacingLG)
                .background(Color.errorRed.opacity(0.15))
                .cornerRadius(LottaPawsTheme.radiusSM)
        }
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
