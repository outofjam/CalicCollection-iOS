import SwiftUI
import SwiftData

struct VariantDetailView: View {
    let variant: CritterVariant
    let critter: Critter
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var ownedVariants: [OwnedVariant]
    @StateObject private var appSettings = AppSettings.shared
    
    @State private var showingFullscreenImage = false
    @State private var showingPurchaseDetails = false
    @State private var showingReportIssue = false
    
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
        return owned.pricePaid != nil || owned.purchaseDate != nil || owned.purchaseLocation != nil || owned.condition != nil || owned.notes != nil
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // MARK: - Hero Image
                    GeometryReader { geometry in
                        ZStack(alignment: .bottomLeading) {
                            // Variant image
                            if let imageURL = variant.imageURL, let url = URL(string: imageURL) {
                                CachedAsyncImage(url: imageURL) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: geometry.size.width, height: 300, alignment: .top)
                                        .clipped()
                                        .onTapGesture {
                                            showingFullscreenImage = true
                                        }
                                } placeholder: {
                                    gradientPlaceholder
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
                            
                            // Variant name overlay
                            VStack(alignment: .leading, spacing: 4) {
                                Text(critter.name)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text(variant.name)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                                
                                if let epochId = variant.epochId, let setName = variant.setName {
                                    HStack(spacing: 4) {
                                        Text("Set \(epochId)")
                                        Text("•")
                                        Text(setName)
                                    }
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                } else if let epochId = variant.epochId {
                                    Text("Set \(epochId)")
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
                        if variant.imageURL != nil {
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
                        
                        // MARK: - Photo Gallery (only for collection items)
                        if isInCollection {
                            PhotoGallerySection(variantUuid: variant.uuid)
                                .padding(.vertical, 8)
                        }
                        
                        // Status Badge
                        if let owned = ownedVariant {
                            HStack {
                                Image(systemName: owned.status == .collection ? "star.fill" : "heart.fill")
                                    .foregroundColor(owned.status == .collection ? .blue : .pink)
                                Text(owned.status == .collection ? "In Collection" : "On Wishlist")
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                Text("Added \(owned.addedDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundColor(.calicoTextSecondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(owned.status == .collection ? Color.blue.opacity(0.1) : Color.pink.opacity(0.1))
                            )
                        }
                        
                        // Info Section
                        VStack(alignment: .leading, spacing: 12) {
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
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Notes")
                                        .font(.caption)
                                        .foregroundColor(.calicoTextSecondary)
                                    Text(notes)
                                        .font(.body)
                                }
                            }
                        }
                        
                        // MARK: - Purchase Details Section (if enabled and owned)
                        if appSettings.showPurchaseDetails, let owned = ownedVariant, owned.status == .collection {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Purchase Details")
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Button {
                                        showingPurchaseDetails = true
                                    } label: {
                                        Text(hasPurchaseDetails ? "Edit" : "Add")
                                            .font(.subheadline)
                                            .foregroundColor(.calicoPrimary)
                                    }
                                }
                                
                                if hasPurchaseDetails {
                                    if let price = owned.pricePaid {
                                        InfoRow(label: "Price Paid", value: String(format: "$%.2f", price))
                                    }
                                    
                                    if let date = owned.purchaseDate {
                                        InfoRow(label: "Purchase Date", value: date.formatted(date: .abbreviated, time: .omitted))
                                    }
                                    
                                    if let location = owned.purchaseLocation {
                                        InfoRow(label: "Store", value: location)
                                    }
                                    
                                    if let condition = owned.condition {
                                        InfoRow(label: "Condition", value: condition)
                                    }
                                    
                                    if let notes = owned.notes {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Notes")
                                                .font(.caption)
                                                .foregroundColor(.calicoTextSecondary)
                                            Text(notes)
                                                .font(.body)
                                        }
                                    }
                                    
                                    HStack(spacing: 16) {
                                        Text("Quantity")
                                            .font(.caption)
                                            .foregroundColor(.calicoTextSecondary)
                                        
                                        Spacer()
                                        
                                        HStack(spacing: 12) {
                                            Button {
                                                if owned.quantity > 1 {
                                                    owned.quantity -= 1
                                                    try? modelContext.save()
                                                }
                                            } label: {
                                                Image(systemName: "minus.circle.fill")
                                                    .foregroundColor(owned.quantity > 1 ? .calicoPrimary : .gray)
                                            }
                                            .disabled(owned.quantity <= 1)
                                            
                                            Text("\(owned.quantity)")
                                                .font(.headline)
                                                .frame(minWidth: 30)
                                            
                                            Button {
                                                owned.quantity += 1
                                                try? modelContext.save()
                                            } label: {
                                                Image(systemName: "plus.circle.fill")
                                                    .foregroundColor(.calicoPrimary)
                                            }
                                        }
                                    }
                                } else {
                                    Text("Tap 'Add' to track purchase details")
                                        .font(.subheadline)
                                        .foregroundColor(.calicoTextSecondary)
                                }
                            }
                            .padding()
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }
                        
                        // Extra bottom padding for sticky action bar
                        Color.clear.frame(height: 80)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
            }
            .ignoresSafeArea(edges: .top)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingReportIssue = true
                        } label: {
                            Label("Report Issue", systemImage: "flag")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                BottomActionBar(
                    isInCollection: isInCollection,
                    isInWishlist: isInWishlist,
                    variantName: variant.name,
                    onAddToCollection: addToCollection,
                    onAddToWishlist: addToWishlist,
                    onMoveToWishlist: moveToWishlist,
                    onRemove: removeVariant
                )
            }
            .fullScreenCover(isPresented: $showingFullscreenImage) {
                if let imageURL = variant.imageURL {
                    FullscreenImageViewer(imageURL: imageURL)
                }
            }
            .sheet(isPresented: $showingPurchaseDetails) {
                if let owned = ownedVariant {
                    PurchaseDetailsSheet(ownedVariant: owned)
                }
            }
            .sheet(isPresented: $showingReportIssue) {
                ReportIssueSheet(variant: variant) { message in
                    // This runs after the sheet dismisses
                    ToastManager.shared.show(message, type: .success)
                }
            }
        }
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
    
    // MARK: - Actions
    
    private func addToCollection() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        try? OwnedVariant.create(variant: variant, critter: critter, status: .collection, in: modelContext)
        
        ToastManager.shared.show("✓ Added \(variant.name) to Collection", type: .success)
    }
    
    private func addToWishlist() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        try? OwnedVariant.create(variant: variant, critter: critter, status: .wishlist, in: modelContext)
        
        ToastManager.shared.show("✓ Added \(variant.name) to Wishlist", type: .success)
    }
    
    private func moveToWishlist() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        try? OwnedVariant.create(variant: variant, critter: critter, status: .wishlist, in: modelContext)
        
        ToastManager.shared.show("✓ Moved \(variant.name) to Wishlist", type: .success)
    }
    
    private func removeVariant() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        
        try? OwnedVariant.remove(variantUuid: variant.uuid, in: modelContext)
        
        ToastManager.shared.show("Removed \(variant.name)", type: .info)
        
        dismiss()
    }
}

// MARK: - Bottom Action Bar
struct BottomActionBar: View {
    let isInCollection: Bool
    let isInWishlist: Bool
    let variantName: String
    let onAddToCollection: () -> Void
    let onAddToWishlist: () -> Void
    let onMoveToWishlist: () -> Void
    let onRemove: () -> Void
    
    @State private var showingRemoveAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                // Primary action button
                if !isInCollection {
                    Button {
                        onAddToCollection()
                    } label: {
                        HStack {
                            Image(systemName: "star.fill")
                            Text("Add to Collection")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.calicoPrimary)
                        .cornerRadius(12)
                    }
                } else {
                    Button {
                        onMoveToWishlist()
                    } label: {
                        HStack {
                            Image(systemName: "heart.fill")
                            Text("Move to Wishlist")
                        }
                        .font(.headline)
                        .foregroundColor(.pink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.pink.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.pink, lineWidth: 1.5)
                        )
                    }
                }
                
                // Secondary actions menu
                if isInCollection || isInWishlist {
                    Menu {
                        if !isInWishlist && !isInCollection {
                            Button {
                                onAddToWishlist()
                            } label: {
                                Label("Add to Wishlist", systemImage: "heart")
                            }
                        }
                        
                        Button(role: .destructive) {
                            showingRemoveAlert = true
                        } label: {
                            Label("Remove from \(isInCollection ? "Collection" : "Wishlist")", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.title2)
                            .foregroundColor(.calicoTextSecondary)
                            .frame(width: 50, height: 50)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(12)
                    }
                } else if !isInCollection {
                    // Wishlist button when not in collection and not in wishlist
                    Button {
                        onAddToWishlist()
                    } label: {
                        Image(systemName: "heart")
                            .font(.title2)
                            .foregroundColor(.pink)
                            .frame(width: 50, height: 50)
                            .background(Color.pink.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.pink, lineWidth: 1.5)
                            )
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(.regularMaterial)
        .alert("Remove \(variantName)?", isPresented: $showingRemoveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                onRemove()
            }
        } message: {
            Text("This will remove \(variantName) from your \(isInCollection ? "collection" : "wishlist").")
        }
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.calicoTextSecondary)
            Spacer()
            Text(value)
                .font(.body)
        }
    }
}

// MARK: - Fullscreen Image Viewer
struct FullscreenImageViewer: View {
    let imageURL: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale)
                            .offset(offset)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = lastScale * value
                                    }
                                    .onEnded { _ in
                                        lastScale = scale
                                        // Reset if zoomed out too far
                                        if scale < 1 {
                                            withAnimation {
                                                scale = 1
                                                lastScale = 1
                                                offset = .zero
                                                lastOffset = .zero
                                            }
                                        }
                                    }
                            )
                            .simultaneousGesture(
                                DragGesture()
                                    .onChanged { value in
                                        if scale > 1 {
                                            offset = CGSize(
                                                width: lastOffset.width + value.translation.width,
                                                height: lastOffset.height + value.translation.height
                                            )
                                        }
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                    }
                            )
                    case .empty:
                        ProgressView()
                            .tint(.white)
                    case .failure:
                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.5))
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            
            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .statusBar(hidden: true)
        .onTapGesture(count: 2) {
            // Double tap to zoom
            withAnimation {
                if scale == 1 {
                    scale = 2
                    lastScale = 2
                } else {
                    scale = 1
                    lastScale = 1
                    offset = .zero
                    lastOffset = .zero
                }
            }
        }
    }
}

#Preview {
    VariantDetailView(
        variant: CritterVariant(
            uuid: "1",
            critterId: "1",
            name: "Royal Princess Set",
            sku: "CC-1234",
            barcode: "123456789",
            imageURL: nil,
            releaseYear: 2023,
            notes: "Limited edition"
        ),
        critter: Critter(
            uuid: "1",
            familyId: "1",
            name: "Bruce Husky",
            memberType: "Kids",
            variantsCount: 1
        )
    )
    .modelContainer(for: OwnedVariant.self, inMemory: true)
}
