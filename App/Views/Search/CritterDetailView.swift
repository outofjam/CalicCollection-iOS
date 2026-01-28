import SwiftUI
import SwiftData

struct CritterDetailView: View {
    let critterUuid: String
    
    @Environment(\.modelContext) private var modelContext
    @Query private var ownedVariants: [OwnedVariant]
    
    @State private var critterData: CritterVariantsResponse?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    @State private var showingVariantPicker = false
    @State private var pickerTargetStatus: CritterStatus = .collection
    @State private var selectedVariantForDetail: VariantResponse?
    
    private var ownedCritterVariants: [OwnedVariant] {
        ownedVariants.filter { $0.critterUuid == critterUuid }
    }
    
    private var hasInCollection: Bool {
        ownedCritterVariants.contains { $0.status == .collection }
    }
    
    private var hasInWishlist: Bool {
        ownedCritterVariants.contains { $0.status == .wishlist }
    }
    
    private var gradientPlaceholder: some View {
        RoundedRectangle(cornerRadius: 0)
            .fill(
                LinearGradient(
                    colors: [Color.blue.opacity(0.3), Color.pink.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 280)
            .overlay {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white.opacity(0.3))
            }
    }
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading critter...")
            } else if let error = errorMessage {
                ContentUnavailableView {
                    Label("Error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    Button("Retry") {
                        Task { await loadCritter() }
                    }
                }
            } else if let data = critterData {
                critterContent(data)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(critterData?.critter.name ?? "Critter")
                    .font(.headline)
            }
        }
        .task {
            await loadCritter()
        }
        .sheet(isPresented: $showingVariantPicker) {
            if let data = critterData {
                VariantPickerSheet(
                    critterUuid: critterUuid,
                    targetStatus: pickerTargetStatus
                )
            }
        }
        .sheet(item: $selectedVariantForDetail) { variant in
            if let critter = critterData?.critter {
                VariantDetailSheet(variant: variant, critter: critter)
            }
        }
    }
    
    @ViewBuilder
    private func critterContent(_ data: CritterVariantsResponse) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // MARK: - Hero Section
                GeometryReader { geometry in
                    ZStack(alignment: .bottomLeading) {
                        // Background image - use primary variant or first variant
                        if let primaryVariant = data.variants.first(where: { $0.isPrimary == true }) ?? data.variants.first,
                           let imageURL = primaryVariant.imageUrl,
                           let url = URL(string: imageURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: geometry.size.width, height: 280, alignment: .top)
                                        .clipped()
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
                        .frame(height: 280)
                        
                        // Critter info overlay
                        VStack(alignment: .leading, spacing: 4) {
                            Text(data.critter.name)
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.white)
                            
                            if let familyName = data.critter.familyName {
                                Text(familyName)
                                    .font(.title3)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            
                            Label(data.critter.memberType.capitalized, systemImage: "person.fill")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(20)
                    }
                }
                .frame(height: 280)
                
                // MARK: - Content Section
                VStack(spacing: 24) {
                    // Variants Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Variants")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Text("\(ownedCritterVariants.count) of \(data.variants.count) owned")
                                .font(.subheadline)
                                .foregroundColor(.calicoTextSecondary)
                        }
                        
                        if data.variants.isEmpty {
                            Text("No variants available")
                                .foregroundColor(.calicoTextSecondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ], spacing: 16) {
                                ForEach(data.variants) { variant in
                                    Button {
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                        selectedVariantForDetail = variant
                                    } label: {
                                        VariantCardOnline(
                                            variant: variant,
                                            isOwned: ownedCritterVariants.contains { $0.variantUuid == variant.uuid }
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // MARK: - Action Buttons
                    if !data.variants.isEmpty {
                        VStack(spacing: 12) {
                            Button {
                                pickerTargetStatus = .collection
                                showingVariantPicker = true
                            } label: {
                                HStack {
                                    Image(systemName: "star.fill")
                                    Text(hasInCollection ? "Manage Collection" : "Add to Collection")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                            
                            Button {
                                pickerTargetStatus = .wishlist
                                showingVariantPicker = true
                            } label: {
                                HStack {
                                    Image(systemName: "heart.fill")
                                    Text(hasInWishlist ? "Manage Wishlist" : "Add to Wishlist")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.pink)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .ignoresSafeArea(edges: .top)
    }
    
    // MARK: - Data Loading
    
    private func loadCritter() async {
        isLoading = true
        errorMessage = nil
        
        do {
            critterData = try await BrowseService.shared.fetchCritterVariants(critterUuid: critterUuid)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

// MARK: - Variant Card (Online Version)
struct VariantCardOnline: View {
    let variant: VariantResponse
    let isOwned: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image container
            ZStack(alignment: .topTrailing) {
                if let urlString = variant.thumbnailUrl ?? variant.imageUrl,
                   let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        default:
                            Color.gray.opacity(0.2)
                                .overlay {
                                    ProgressView()
                                }
                        }
                    }
                } else {
                    Color.gray.opacity(0.2)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        }
                }
                
                // Primary badge
                if variant.isPrimary == true {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                        Text("Primary")
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.orange)
                    .cornerRadius(4)
                    .padding(6)
                }
                
                // Owned checkmark
                if isOwned {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.calicoSuccess)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .frame(width: 20, height: 20)
                        )
                        .padding(8)
                        .offset(y: variant.isPrimary == true ? 28 : 0)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Variant info
            VStack(alignment: .leading, spacing: 4) {
                Text(variant.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                if let epochId = variant.epochId, let setName = variant.setName {
                    Text("Set \(epochId)")
                        .font(.caption2)
                        .foregroundColor(.calicoTextSecondary)
                    Text(setName)
                        .font(.caption2)
                        .foregroundColor(.calicoTextSecondary)
                        .lineLimit(1)
                } else if let epochId = variant.epochId {
                    Text("Set \(epochId)")
                        .font(.caption2)
                        .foregroundColor(.calicoTextSecondary)
                } else if let sku = variant.sku {
                    Text("SKU: \(sku)")
                        .font(.caption2)
                        .foregroundColor(.calicoTextSecondary)
                }
            }
        }
    }
}

// MARK: - Variant Detail Sheet
struct VariantDetailSheet: View {
    let variant: VariantResponse
    let critter: CritterInfo
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var ownedVariants: [OwnedVariant]
    
    @State private var showingReportIssue = false
    @State private var isAdding = false
    
    private var isOwned: Bool {
        ownedVariants.contains { $0.variantUuid == variant.uuid }
    }
    
    private var ownedStatus: CritterStatus? {
        ownedVariants.first { $0.variantUuid == variant.uuid }?.status
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Image
                    if let urlString = variant.imageUrl, let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 300)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            default:
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 200)
                                    .overlay { ProgressView() }
                            }
                        }
                    }
                    
                    // Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text(variant.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(critter.name)
                            .font(.headline)
                            .foregroundColor(.calicoTextSecondary)
                        
                        if let familyName = critter.familyName {
                            Text(familyName)
                                .font(.subheadline)
                                .foregroundColor(.calicoTextSecondary)
                        }
                        
                        Divider()
                        
                        if let setName = variant.setName {
                            DetailRow(label: "Set", value: setName)
                        }
                        if let epochId = variant.epochId {
                            DetailRow(label: "Set ID", value: epochId)
                        }
                        if let sku = variant.sku {
                            DetailRow(label: "SKU", value: sku)
                        }
                        if let year = variant.releaseYear {
                            DetailRow(label: "Release Year", value: "\(year)")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button {
                            Task { await addToCollection() }
                        } label: {
                            HStack {
                                Image(systemName: ownedStatus == .collection ? "checkmark.circle.fill" : "star")
                                Text(ownedStatus == .collection ? "In Collection" : "Add to Collection")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ownedStatus == .collection ? Color.green : Color.blue)
                            .cornerRadius(12)
                        }
                        .disabled(isAdding)
                        
                        Button {
                            Task { await addToWishlist() }
                        } label: {
                            HStack {
                                Image(systemName: ownedStatus == .wishlist ? "checkmark.circle.fill" : "heart")
                                Text(ownedStatus == .wishlist ? "In Wishlist" : "Add to Wishlist")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ownedStatus == .wishlist ? Color.green : Color.pink)
                            .cornerRadius(12)
                        }
                        .disabled(isAdding)
                        
                        if isOwned {
                            Button(role: .destructive) {
                                removeFromCollection()
                            } label: {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Remove")
                                }
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Variant Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
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
                    }
                }
            }
            .sheet(isPresented: $showingReportIssue) {
                ReportIssueSheet(variantUuid: variant.uuid, variantName: variant.name)
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
    }
    
    private func addToCollection() async {
        isAdding = true
        do {
            try await OwnedVariant.create(
                variant: variant,
                critter: critter,
                familyId: critter.familyUuid ?? "",
                status: .collection,
                in: modelContext
            )
            ToastManager.shared.show("✓ Added to Collection", type: .success)
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
                familyId: critter.familyUuid ?? "",
                status: .wishlist,
                in: modelContext
            )
            ToastManager.shared.show("✓ Added to Wishlist", type: .success)
        } catch {
            ToastManager.shared.show("Failed to add", type: .error)
        }
        isAdding = false
    }
    
    private func removeFromCollection() {
        try? OwnedVariant.remove(variantUuid: variant.uuid, in: modelContext)
        ToastManager.shared.show("Removed", type: .info)
        dismiss()
    }
}

// MARK: - Detail Row
private struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.calicoTextSecondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    NavigationStack {
        CritterDetailView(critterUuid: "test-uuid")
    }
}
