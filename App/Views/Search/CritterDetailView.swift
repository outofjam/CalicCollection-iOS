import SwiftUI
import SwiftUI
import SwiftData

struct CritterDetailView: View {
    let critter: Critter
    
    @Environment(\.modelContext) private var modelContext
    @Query private var allVariants: [CritterVariant]
    @Query private var ownedVariants: [OwnedVariant]
    
    @State private var showingVariantPicker = false
    @State private var pickerTargetStatus: CritterStatus = .collection
    
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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Critter Image (placeholder for now)
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 300)
                    .overlay {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                
                // MARK: - Critter Info
                VStack(spacing: 8) {
                    Text(critter.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    if let familyName = critter.familyName {
                        Text(familyName)
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    
                    if let familySpecies = critter.familySpecies {
                        Text(familySpecies)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 12) {
                        Label(critter.memberType, systemImage: "person.fill")
                        
                        if let role = critter.role {
                            Text("•")
                            Text(role)
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    
                    if let barcode = critter.barcode {
                        Text("Barcode: \(barcode)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // MARK: - Variants Section
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
                        ], spacing: 12) {
                            ForEach(critterVariants) { variant in
                                VariantCard(
                                    variant: variant,
                                    isOwned: ownedCritterVariants.contains { $0.variantUuid == variant.uuid }
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
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
                    .padding()
                }
            }
            .padding(.top)
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingVariantPicker) {
            VariantPickerSheet(
                critter: critter,
                targetStatus: pickerTargetStatus
            )
        }
    }
}

// MARK: - Variant Card
struct VariantCard: View {
    let variant: CritterVariant
    let isOwned: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    if let imageURL = variant.imageURL {
                        AsyncImage(url: URL(string: imageURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ProgressView()
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if isOwned {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .background(Circle().fill(Color.white))
                            .padding(8)
                    }
                }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(variant.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                if let sku = variant.sku {
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
