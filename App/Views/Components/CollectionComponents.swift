//
//  CollectionListView.swift
//  LottaPaws
//

import SwiftUI
import SwiftData

// MARK: - List View
struct CollectionListView: View {
    let groupedVariants: [String: [OwnedVariant]]
    let sortedGroupNames: [String]
    @Binding var selectedVariant: OwnedVariant?
    
    var body: some View {
        List {
            ForEach(sortedGroupNames, id: \.self) { familyName in
                Section {
                    // Family header as first tappable row
                    if let familyUuid = groupedVariants[familyName]?.first?.familyId {
                        NavigationLink {
                            FamilyDetailView(familyUuid: familyUuid, familyName: familyName)
                        } label: {
                            HStack {
                                Text(familyName)
                                    .font(.headline)
                                    .foregroundColor(.textPrimary)
                                Spacer()
                                if let variants = groupedVariants[familyName] {
                                    Text("\(variants.count) variant\(variants.count == 1 ? "" : "s")")
                                        .font(.caption)
                                        .foregroundColor(.textTertiary)
                                }
                            }
                            .padding(.vertical, LottaPawsTheme.spacingXS)
                        }
                    } else {
                        // Fallback if no UUID (shouldn't happen)
                        HStack {
                            Text(familyName)
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                            Spacer()
                            if let variants = groupedVariants[familyName] {
                                Text("\(variants.count) variant\(variants.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundColor(.textTertiary)
                            }
                        }
                        .padding(.vertical, LottaPawsTheme.spacingXS)
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
    
    @Environment(\.modelContext) private var modelContext
    @Query private var allPhotos: [VariantPhoto]
    
    private var firstPhoto: VariantPhoto? {
        allPhotos
            .filter { $0.variantUuid == variant.variantUuid }
            .sorted { $0.sortOrder < $1.sortOrder }
            .first
    }
    
    var body: some View {
        HStack(spacing: LottaPawsTheme.spacingMD) {
            // Show user photo if available, then local cached image, then remote
            if let photo = firstPhoto, let uiImage = UIImage(data: photo.imageData) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                    
                    // Badge to indicate user photo
                    Image(systemName: "camera.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.white)
                        .padding(3)
                        .background(Circle().fill(Color.primaryPink))
                        .offset(x: -2, y: 2)
                }
                .clipShape(RoundedRectangle(cornerRadius: LottaPawsTheme.radiusSM))
            } else if let localPath = variant.localThumbnailPath,
                      let uiImage = UIImage(contentsOfFile: localPath) {
                // Local cached thumbnail
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: LottaPawsTheme.radiusSM))
            } else if let urlString = variant.thumbnailURL ?? variant.imageURL,
                      let url = URL(string: urlString) {
                // Remote URL fallback
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: LottaPawsTheme.radiusSM))
                    default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
            
            // Variant info
            VStack(alignment: .leading, spacing: LottaPawsTheme.spacingXS) {
                Text(variant.critterName)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                Text(variant.variantName)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                
                // Single line with date and photo count
                HStack(spacing: LottaPawsTheme.spacingXS) {
                    Text("Added \(variant.addedDate.formatted(date: .abbreviated, time: .omitted))")
                    
                    if firstPhoto != nil {
                        let photoCount = allPhotos.filter { $0.variantUuid == variant.variantUuid }.count
                        Text("•")
                        Image(systemName: "photo")
                            .font(.system(size: 10))
                        Text("\(photoCount)")
                            .foregroundColor(.primaryPink)
                    }
                }
                .font(.caption)
                .foregroundColor(.textTertiary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.textTertiary)
        }
        .listRowSeparator(.visible)
        .alignmentGuide(.listRowSeparatorLeading) { _ in
            60 + LottaPawsTheme.spacingMD   // image width + HStack spacing
        }
        .listRowInsets(EdgeInsets(top: LottaPawsTheme.spacingSM, leading: LottaPawsTheme.spacingLG, bottom: LottaPawsTheme.spacingSM, trailing: LottaPawsTheme.spacingLG))
    }
    
    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: LottaPawsTheme.radiusSM)
            .fill(Color.backgroundTertiary)
            .frame(width: 60, height: 60)
            .overlay {
                Image(systemName: "photo")
                    .foregroundColor(.textTertiary)
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
                                GridItem(.flexible(), spacing: LottaPawsTheme.spacingSM),
                                GridItem(.flexible(), spacing: LottaPawsTheme.spacingSM),
                                GridItem(.flexible(), spacing: LottaPawsTheme.spacingSM)
                            ], spacing: LottaPawsTheme.spacingSM) {
                                ForEach(variants, id: \.variantUuid) { variant in
                                    Button {
                                        selectedVariant = variant
                                    } label: {
                                        GalleryImageCard(variant: variant)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, LottaPawsTheme.spacingSM)
                            .padding(.bottom, LottaPawsTheme.spacingLG)
                        }
                    } header: {
                        if let familyUuid = groupedVariants[familyName]?.first?.familyId {
                            NavigationLink {
                                FamilyDetailView(familyUuid: familyUuid, familyName: familyName)
                            } label: {
                                familyHeader(familyName: familyName)
                            }
                        } else {
                            familyHeader(familyName: familyName)
                        }
                    }
                }
            }
        }
        .background(Color.backgroundPrimary)
    }
    
    private func familyHeader(familyName: String) -> some View {
        HStack {
            Text(familyName)
                .font(.headline)
                .foregroundColor(.textPrimary)
            Spacer()
            if let variants = groupedVariants[familyName] {
                Text("\(variants.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.textTertiary)
                    .padding(.horizontal, LottaPawsTheme.spacingSM)
                    .padding(.vertical, LottaPawsTheme.spacingXS)
                    .background(Color.backgroundTertiary)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, LottaPawsTheme.spacingLG)
        .padding(.vertical, LottaPawsTheme.spacingMD)
        .frame(maxWidth: .infinity)
        .background(Color.backgroundPrimary)
    }
}

// MARK: - Gallery Image Card
struct GalleryImageCard: View {
    let variant: OwnedVariant
    
    @Environment(\.modelContext) private var modelContext
    @Query private var allPhotos: [VariantPhoto]
    
    private var firstPhoto: VariantPhoto? {
        allPhotos
            .filter { $0.variantUuid == variant.variantUuid }
            .sorted { $0.sortOrder < $1.sortOrder }
            .first
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                // Show user photo if available, then local cached, then remote
                if let photo = firstPhoto, let uiImage = UIImage(data: photo.imageData) {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                        
                        // Badge to indicate user photo
                        Image(systemName: "camera.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Circle().fill(Color.primaryPink))
                            .offset(x: -4, y: 4)
                    }
                } else if let localPath = variant.localThumbnailPath,
                          let uiImage = UIImage(contentsOfFile: localPath) {
                    // Local cached thumbnail
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                } else if let urlString = variant.thumbnailURL ?? variant.imageURL,
                          let url = URL(string: urlString) {
                    // Remote URL fallback
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                        default:
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
                .padding(LottaPawsTheme.spacingSM)
            }
            .clipShape(RoundedRectangle(cornerRadius: LottaPawsTheme.radiusSM))
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    private func placeholderImage(width: CGFloat, height: CGFloat) -> some View {
        Color.backgroundTertiary
            .frame(width: width, height: height)
            .overlay {
                Image(systemName: "photo")
                    .foregroundColor(.textTertiary)
            }
    }
}
