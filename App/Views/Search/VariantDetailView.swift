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
    @State private var showConfetti = false
    
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
                            if let imageURL = variant.imageUrl, let url = URL(string: imageURL) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: geometry.size.width, height: 300, alignment: .top)
                                            .clipped()
                                            .onTapGesture {
                                                showingFullscreenImage = true
                                            }
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
                            
                            // Expand button (bottom-right)
                            if variant.imageUrl != nil {
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Button {
                                            showingFullscreenImage = true
                                        } label: {
                                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.white)
                                                .padding(8)
                                                .background(Color.black.opacity(0.5))
                                                .clipShape(Circle())
                                        }
                                        .padding(12)
                                    }
                                }
                                .frame(height: 300)
                            }
                            
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
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Notes")
                                        .font(.caption)
                                        .foregroundColor(.calicoTextSecondary)
                                    Text(notes)
                                        .font(.body)
                                }
                            }
                        }
                        
                        // MARK: - Purchase Details Section
                        if appSettings.showPurchaseDetails, let owned = ownedVariant, owned.status == .collection {
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
                ReportIssueSheetOnline(variantUuid: variant.uuid, variantName: variant.name)
            }
            .overlay {
                if isAdding {
                    ZStack {
                        Color.black.opacity(0.3)
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                    }
                    .ignoresSafeArea()
                }
            }
        }
        .confetti(isShowing: $showConfetti).toast()
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
    
    private func addToCollection() async {
        isAdding = true
        
        do {
            try await OwnedVariant.create(
                variant: variant,
                critter: critter,
                familyId: familyUuid,
                status: .collection,
                in: modelContext
            )
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            // Trigger confetti if enabled
            if AppSettings.shared.showConfetti {
                showConfetti = true
            }
            
            ToastManager.shared.show("✓ Added \(variant.name) to Collection", type: .success)
        } catch {
            ToastManager.shared.show("Failed to add", type: .error)
        }
        
        isAdding = false
    }
    
    private func addToWishlist() async {
        isAdding = true
        
        do {
            try await OwnedVariant.create(
                variant: variant,
                critter: critter,
                familyId: familyUuid,
                status: .wishlist,
                in: modelContext
            )
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            ToastManager.shared.show("✓ Added \(variant.name) to Wishlist", type: .success)
        } catch {
            ToastManager.shared.show("Failed to add", type: .error)
        }
        
        isAdding = false
    }
    
    private func moveToWishlist() async {
        isAdding = true
        
        do {
            try await OwnedVariant.create(
                variant: variant,
                critter: critter,
                familyId: familyUuid,
                status: .wishlist,
                in: modelContext
            )
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            ToastManager.shared.show("✓ Moved \(variant.name) to Wishlist", type: .success)
        } catch {
            ToastManager.shared.show("Failed to move", type: .error)
        }
        
        isAdding = false
    }
    
    private func removeVariant() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        
        try? OwnedVariant.remove(variantUuid: variant.uuid, in: modelContext)
        
        ToastManager.shared.show("Removed \(variant.name)", type: .info)
        
        dismiss()
    }
}


// MARK: - Purchase Details Section
struct PurchaseDetailsSection: View {
    let ownedVariant: OwnedVariant
    let hasPurchaseDetails: Bool
    @Binding var showingPurchaseDetails: Bool
    let modelContext: ModelContext
    
    var body: some View {
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
                if let price = ownedVariant.pricePaid {
                    InfoRow(label: "Price Paid", value: String(format: "$%.2f", price))
                }
                
                if let date = ownedVariant.purchaseDate {
                    InfoRow(label: "Purchase Date", value: date.formatted(date: .abbreviated, time: .omitted))
                }
                
                if let location = ownedVariant.purchaseLocation {
                    InfoRow(label: "Store", value: location)
                }
                
                if let condition = ownedVariant.condition {
                    InfoRow(label: "Condition", value: condition)
                }
                
                if let notes = ownedVariant.notes {
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
                            if ownedVariant.quantity > 1 {
                                ownedVariant.quantity -= 1
                                try? modelContext.save()
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(ownedVariant.quantity > 1 ? .calicoPrimary : .gray)
                        }
                        .disabled(ownedVariant.quantity <= 1)
                        
                        Text("\(ownedVariant.quantity)")
                            .font(.headline)
                            .frame(minWidth: 30)
                        
                        Button {
                            ownedVariant.quantity += 1
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
}

// MARK: - Report Issue Sheet (Online version)
struct ReportIssueSheetOnline: View {
    let variantUuid: String
    let variantName: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var issueType: ReportIssueType = .incorrectImage
    @State private var details: String = ""
    @State private var suggestedCorrection: String = ""
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Issue Type") {
                    Picker("Type", selection: $issueType) {
                        ForEach(ReportIssueType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Details") {
                    TextField("Describe the issue...", text: $details, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Suggested Correction (Optional)") {
                    TextField("What should it be?", text: $suggestedCorrection, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Report Issue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        Task { await submitReport() }
                    }
                    .disabled(details.isEmpty || isSubmitting)
                }
            }
            .overlay {
                if isSubmitting {
                    ProgressView()
                }
            }
        }
    }
    
    private func submitReport() async {
        isSubmitting = true
        
        do {
            let message = try await APIService.shared.submitReport(
                variantUuid: variantUuid,
                issueType: issueType,
                details: details.isEmpty ? nil : details,
                suggestedCorrection: suggestedCorrection.isEmpty ? nil : suggestedCorrection
            )
            
            ToastManager.shared.show(message, type: .success)
            dismiss()
        } catch {
            ToastManager.shared.show("Failed to submit report", type: .error)
        }
        
        isSubmitting = false
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
