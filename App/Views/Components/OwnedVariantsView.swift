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
            variant.familyName ?? "Unknown Family"
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
                OwnedVariantDetailView(ownedVariant: variant)
            }
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
                    GeometryReader { geometry in
                        ZStack(alignment: .bottomLeading) {
                            // Try local image first, then remote
                            if let localPath = ownedVariant.localImagePath,
                               let uiImage = UIImage(contentsOfFile: localPath) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geometry.size.width, height: 300, alignment: .top)
                                    .clipped()
                                    .onTapGesture { showingFullscreenImage = true }
                            } else if let imageURL = ownedVariant.imageURL,
                                      let url = URL(string: imageURL) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: geometry.size.width, height: 300, alignment: .top)
                                            .clipped()
                                            .onTapGesture { showingFullscreenImage = true }
                                    default:
                                        gradientPlaceholder
                                    }
                                }
                            } else {
                                gradientPlaceholder
                            }
                            
                            // Gradient overlay
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 300)
                            
                            // Info overlay
                            VStack(alignment: .leading, spacing: 4) {
                                Text(ownedVariant.critterName)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text(ownedVariant.variantName)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                                
                                if let familyName = ownedVariant.familyName {
                                    Text(familyName)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            .padding(20)
                        }
                    }
                    .frame(height: 300)
                    
                    // MARK: - Content
                    VStack(spacing: 24) {
                        // Tap to expand hint
                        if ownedVariant.imageURL != nil || ownedVariant.localImagePath != nil {
                            Button {
                                showingFullscreenImage = true
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    Text("Tap to view full size")
                                        .font(.subheadline)
                                }
                                .foregroundColor(.calicoPrimary)
                            }
                        }
                        
                        // Photo Gallery (collection items only)
                        if ownedVariant.status == .collection {
                            PhotoGallerySection(variantUuid: ownedVariant.variantUuid)
                                .padding(.vertical, 8)
                        }
                        
                        // Status Badge
                        HStack {
                            Image(systemName: ownedVariant.status == .collection ? "star.fill" : "heart.fill")
                                .foregroundColor(ownedVariant.status == .collection ? .blue : .pink)
                            Text(ownedVariant.status == .collection ? "In Collection" : "On Wishlist")
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text("Added \(ownedVariant.addedDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundColor(.calicoTextSecondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(ownedVariant.status == .collection ? Color.blue.opacity(0.1) : Color.pink.opacity(0.1))
                        )
                        
                        // Info Section
                        VStack(alignment: .leading, spacing: 12) {
                            if let familyName = ownedVariant.familyName {
                                InfoRow(label: "Family", value: familyName)
                            }
                            
                            InfoRow(label: "Member Type", value: ownedVariant.memberType.capitalized)
                            
                            if let role = ownedVariant.role {
                                InfoRow(label: "Role", value: role)
                            }
                        }
                        
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
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                OwnedVariantActionBar(
                    ownedVariant: ownedVariant,
                    onRemove: { removeVariant() },
                    onMoveToWishlist: { moveToWishlist() },
                    onMoveToCollection: { moveToCollection() }
                )
            }
            .fullScreenCover(isPresented: $showingFullscreenImage) {
                if let localPath = ownedVariant.localImagePath {
                    FullscreenLocalImageViewer(imagePath: localPath)
                } else if let imageURL = ownedVariant.imageURL {
                    FullscreenImageViewer(imageURL: imageURL)
                }
            }
            .sheet(isPresented: $showingPurchaseDetails) {
                PurchaseDetailsSheet(ownedVariant: ownedVariant)
            }
        }.toast()
    }
    
    private var gradientPlaceholder: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.blue.opacity(0.3), Color.pink.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 300)
            .overlay {
                Image(systemName: "photo")
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.3))
            }
    }
    
    private func removeVariant() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        
        try? OwnedVariant.remove(variantUuid: ownedVariant.variantUuid, in: modelContext)
        ToastManager.shared.show("Removed \(ownedVariant.variantName)", type: .info)
        dismiss()
    }
    
    private func moveToWishlist() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        ownedVariant.status = .wishlist
        try? modelContext.save()
        ToastManager.shared.show("✓ Moved to Wishlist", type: .success)
    }
    
    private func moveToCollection() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
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
        HStack(spacing: 12) {
            if ownedVariant.status == .collection {
                // Move to Wishlist button
                Button {
                    onMoveToWishlist()
                } label: {
                    HStack {
                        Image(systemName: "heart")
                        Text("Move to Wishlist")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.pink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.pink.opacity(0.1))
                    .cornerRadius(10)
                }
            } else {
                // Move to Collection button
                Button {
                    onMoveToCollection()
                } label: {
                    HStack {
                        Image(systemName: "star")
                        Text("Move to Collection")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            
            // Remove button
            Button {
                onRemove()
            } label: {
                Image(systemName: "trash")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.red)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}

// MARK: - Fullscreen Local Image Viewer
struct FullscreenLocalImageViewer: View {
    let imagePath: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let uiImage = UIImage(contentsOfFile: imagePath) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = value
                            }
                            .onEnded { _ in
                                withAnimation {
                                    scale = max(1.0, min(scale, 3.0))
                                }
                            }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation {
                            scale = scale > 1.0 ? 1.0 : 2.0
                        }
                    }
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .onTapGesture {
            dismiss()
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
