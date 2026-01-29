//
//  VariantHeroImage.swift
//  LottaPaws
//
//  Shared hero image component for variant detail views.
//  Handles local cached images, remote URLs, and placeholder states.
//

import SwiftUI

struct VariantHeroImage: View {
    let localImagePath: String?
    let remoteImageURL: String?
    let title: String
    let subtitle: String
    let caption: String?
    let onExpandTap: () -> Void
    
    private let heroHeight: CGFloat = 300
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                // Image layer (local → remote → placeholder)
                imageLayer(width: geometry.size.width)
                
                // Gradient overlay
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: heroHeight)
                
                // Expand button (bottom-right)
                if hasImage {
                    expandButton
                }
                
                // Text overlay (bottom-left)
                textOverlay
            }
        }
        .frame(height: heroHeight)
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func imageLayer(width: CGFloat) -> some View {
        if let localPath = localImagePath,
           let uiImage = UIImage(contentsOfFile: localPath) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width, height: heroHeight, alignment: .top)
                .clipped()
                .contentShape(Rectangle())
                .onTapGesture { onExpandTap() }
        } else if let imageURL = remoteImageURL,
                  let url = URL(string: imageURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: width, height: heroHeight, alignment: .top)
                        .clipped()
                        .contentShape(Rectangle())
                        .onTapGesture { onExpandTap() }
                default:
                    gradientPlaceholder
                }
            }
        } else {
            gradientPlaceholder
        }
    }
    
    private var expandButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    onExpandTap()
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(LottaPawsTheme.spacingSM)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
                .padding(LottaPawsTheme.spacingMD)
            }
        }
        .frame(height: heroHeight)
    }
    
    private var textOverlay: some View {
        VStack(alignment: .leading, spacing: LottaPawsTheme.spacingXS) {
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            
            if let caption = caption {
                Text(caption)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(LottaPawsTheme.spacingXL)
    }
    
    private var gradientPlaceholder: some View {
        Rectangle()
            .fill(LinearGradient.lottaGradient.opacity(0.5))
            .frame(height: heroHeight)
            .overlay {
                Image(systemName: "photo")
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.3))
            }
    }
    
    // MARK: - Helpers
    
    private var hasImage: Bool {
        localImagePath != nil || remoteImageURL != nil
    }
}

// MARK: - Convenience Initializers

extension VariantHeroImage {
    /// Initialize from API response (VariantResponse + CritterInfo)
    init(
        variant: VariantResponse,
        critter: CritterInfo,
        onExpandTap: @escaping () -> Void
    ) {
        self.localImagePath = nil
        self.remoteImageURL = variant.imageUrl
        self.title = critter.name
        self.subtitle = variant.name
        
        // Build caption from epoch/set info
        if let epochId = variant.epochId, let setName = variant.setName {
            self.caption = "Set \(epochId) • \(setName)"
        } else if let epochId = variant.epochId {
            self.caption = "Set \(epochId)"
        } else {
            self.caption = nil
        }
        
        self.onExpandTap = onExpandTap
    }
    
    /// Initialize from owned variant (OwnedVariant)
    init(
        ownedVariant: OwnedVariant,
        onExpandTap: @escaping () -> Void
    ) {
        self.localImagePath = ownedVariant.localImagePath
        self.remoteImageURL = ownedVariant.imageURL
        self.title = ownedVariant.critterName
        self.subtitle = ownedVariant.variantName
        
        // Build caption from epoch/set info (same logic as API variant)
        if let epochId = ownedVariant.epochId, let setName = ownedVariant.setName {
            self.caption = "Set \(epochId) • \(setName)"
        } else if let epochId = ownedVariant.epochId {
            self.caption = "Set \(epochId)"
        } else {
            self.caption = ownedVariant.familyName
        }
        
        self.onExpandTap = onExpandTap
    }
}

#Preview("With Remote Image") {
    VariantHeroImage(
        localImagePath: nil,
        remoteImageURL: "https://example.com/image.jpg",
        title: "Stella Hopscotch",
        subtitle: "Original Release",
        caption: "Chocolate Rabbit Family",
        onExpandTap: {}
    )
}

#Preview("Placeholder") {
    VariantHeroImage(
        localImagePath: nil,
        remoteImageURL: nil,
        title: "Stella Hopscotch",
        subtitle: "Original Release",
        caption: nil,
        onExpandTap: {}
    )
}
