import SwiftUI
import SwiftData

struct CritterDetailView: View {
    let critter: Critter
    
    @Environment(\.modelContext) private var modelContext
    @Query private var allVariants: [CritterVariant]
    @Query private var ownedVariants: [OwnedVariant]
    
    @State private var showingVariantPicker = false
    @State private var pickerTargetStatus: CritterStatus = .collection
    @State private var selectedVariantForDetail: CritterVariant?
    
    private var critterVariants: [CritterVariant] {
        allVariants.filter { $0.critterId == critter.uuid }
    }
    
    private var ownedCritterVariants: [OwnedVariant] {
        ownedVariants.filter { $0.critterUuid == critter.uuid }
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
        ScrollView {
            VStack(spacing: 0) {
                // MARK: - Hero Section (Image + Info Overlay)
                GeometryReader { geometry in
                    ZStack(alignment: .bottomLeading) {
                        // Background image - first variant (use full image for hero)
                        if let firstVariant = critterVariants.first,
                           let imageURL = firstVariant.imageURL,
                           let url = URL(string: imageURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    gradientPlaceholder
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: geometry.size.width, height: 280, alignment: .top)
                                        .clipped()
                                case .failure:
                                    gradientPlaceholder
                                @unknown default:
                                    gradientPlaceholder
                                }
                            }
                        } else {
                            gradientPlaceholder
                        }
                        
                        // Gradient overlay for text readability
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 280)
                        
                        // Critter info overlay
                        VStack(alignment: .leading, spacing: 4) {
                            Text(critter.name)
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.white)
                            
                            if let familyName = critter.familyName {
                                Text(familyName)
                                    .font(.title3)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            
                            if let familySpecies = critter.familySpecies {
                                Text(familySpecies)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            HStack(spacing: 8) {
                                Label(critter.memberType, systemImage: "person.fill")
                                
                                if let role = critter.role {
                                    Text("•")
                                    Text(role)
                                }
                            }
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
                            
                            Text("\(ownedCritterVariants.count) of \(critter.variantsCount) owned")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if critterVariants.isEmpty {
                            Text("No variants available")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ], spacing: 16) {
                                ForEach(critterVariants) { variant in
                                    Button {
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                        selectedVariantForDetail = variant
                                    } label: {
                                        VariantCard(
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
                    if critter.variantsCount > 0 {
                        VStack(spacing: 12) {
                            Button {
                                pickerTargetStatus = .collection
                                showingVariantPicker = true
                            } label: {
                                HStack {
                                    Image(systemName: "star.fill")
                                    Text(hasInCollection ? "Manage Collection Variants" : "Add to Collection")
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
                                    Text(hasInWishlist ? "Manage Wishlist Variants" : "Add to Wishlist")
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(critter.name)
                    .font(.headline)
            }
        }
        .sheet(isPresented: $showingVariantPicker) {
            VariantPickerSheet(
                critter: critter,
                targetStatus: pickerTargetStatus
            )
        }
        .sheet(item: $selectedVariantForDetail) { variant in
            VariantDetailView(variant: variant, critter: critter)
        }
    }
}

// MARK: - Variant Card
struct VariantCard: View {
    let variant: CritterVariant
    let isOwned: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image container (use thumbnail for grid performance)
            ZStack(alignment: .topTrailing) {
                // Use thumbnail if available, fallback to full image
                if let urlString = variant.thumbnailURL ?? variant.imageURL,
                   let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Color.gray.opacity(0.2)
                                .overlay {
                                    ProgressView()
                                }
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        case .failure:
                            Color.gray.opacity(0.2)
                                .overlay {
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                }
                        @unknown default:
                            Color.gray.opacity(0.2)
                        }
                    }
                } else {
                    Color.gray.opacity(0.2)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        }
                }
                
                // Owned checkmark
                if isOwned {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .frame(width: 20, height: 20)
                        )
                        .padding(8)
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
                        .foregroundColor(.secondary)
                    Text(setName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else if let epochId = variant.epochId {
                    Text("Set \(epochId)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else if let sku = variant.sku {
                    Text("SKU: \(sku)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CritterDetailView(
            critter: Critter(
                uuid: "1",
                familyId: "1",
                name: "Linnea Husky",
                memberType: "Babies",
                role: "Baby Sister",
                familyName: "Husky Dog",
                familySpecies: "Dog",
                variantsCount: 8
            )
        )
    }
    .modelContainer(for: OwnedVariant.self, inMemory: true)
}
