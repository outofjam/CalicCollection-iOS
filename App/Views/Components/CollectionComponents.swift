import SwiftUI
import SwiftData

// MARK: - List View
struct CollectionListView: View {
    let groupedVariants: [String: [OwnedVariant]]
    let sortedGroupNames: [String]  // Changed from sortedCritterNames - now holds family names
    @Binding var selectedVariant: OwnedVariant?
    
    var body: some View {
        List {
            ForEach(sortedGroupNames, id: \.self) { familyName in
                Section {
                    // Family header as first tappable row
                    NavigationLink {
                        FamilyDetailView(familyName: familyName)
                    } label: {
                        HStack {
                            Text(familyName)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                            if let variants = groupedVariants[familyName] {
                                Text("\(variants.count) variant\(variants.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // Variants
                    if let variants = groupedVariants[familyName] {
                        ForEach(variants, id: \.variantUuid) { variant in
                            Button {
                                selectedVariant = variant
                            } label: {
                                CollectionListRow(variant: variant)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - List Row
struct CollectionListRow: View {
    let variant: OwnedVariant
    
    var body: some View {
        HStack(spacing: 12) {
            // Variant image (use thumbnail for list performance)
            if let urlString = variant.thumbnailURL ?? variant.imageURL,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    case .empty:
                        placeholderImage
                    case .failure:
                        placeholderImage
                    @unknown default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
            
            // Variant info
            VStack(alignment: .leading, spacing: 4) {
                Text(variant.critterName)
                    .font(.headline)
                
                Text(variant.variantName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Added \(variant.addedDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.2))
            .frame(width: 60, height: 60)
            .overlay {
                Image(systemName: "photo")
                    .foregroundColor(.gray)
            }
    }
}

// MARK: - Gallery View
struct CollectionGalleryView: View {
    let groupedVariants: [String: [OwnedVariant]]
    let sortedGroupNames: [String]
    @Binding var selectedVariant: OwnedVariant?
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(sortedGroupNames, id: \.self) { familyName in
                    Section {
                        if let variants = groupedVariants[familyName] {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 8),
                                GridItem(.flexible(), spacing: 8),
                                GridItem(.flexible(), spacing: 8)
                            ], spacing: 8) {
                                ForEach(variants, id: \.variantUuid) { variant in
                                    Button {
                                        selectedVariant = variant
                                    } label: {
                                        GalleryImageCard(variant: variant)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.bottom, 16)
                        }
                    } header: {
                        NavigationLink {
                            FamilyDetailView(familyName: familyName)
                        } label: {
                            HStack {
                                Text(familyName)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                if let variants = groupedVariants[familyName] {
                                    Text("\(variants.count)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Color(uiColor: .systemBackground))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Gallery Image Card
struct GalleryImageCard: View {
    let variant: OwnedVariant
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                // Image (use thumbnail for gallery performance)
                if let urlString = variant.thumbnailURL ?? variant.imageURL,
                   let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                        case .empty:
                            placeholderImage(width: geometry.size.width, height: geometry.size.height)
                        case .failure:
                            placeholderImage(width: geometry.size.width, height: geometry.size.height)
                        @unknown default:
                            placeholderImage(width: geometry.size.width, height: geometry.size.height)
                        }
                    }
                } else {
                    placeholderImage(width: geometry.size.width, height: geometry.size.height)
                }
                
                // Gradient overlay with name
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(variant.variantName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text(variant.critterName)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                }
                .padding(6)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    private func placeholderImage(width: CGFloat, height: CGFloat) -> some View {
        Color.gray.opacity(0.2)
            .frame(width: width, height: height)
            .overlay {
                Image(systemName: "photo")
                    .foregroundColor(.gray)
            }
    }
}
