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
    let memberType: String
    let birthday: String?
    let species: String?
    let onExpandTap: () -> Void
    
    private let heroHeight: CGFloat = 300
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Image layer (local → remote → placeholder)
                imageLayer(width: geometry.size.width)
                
                // Gradient overlay
                LinearGradient(
                    colors: [.clear, .clear, .black.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: heroHeight)
                
                // Expand button (top-right, moved up so it doesn't compete with card)
                if hasImage {
                    expandButton
                }
                
                // Trading card overlay
                tradingCardOverlay
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
//            Spacer()
        }
        .frame(height: heroHeight)
    }
    
    private var tradingCardOverlay: some View {
        VStack(alignment: .leading, spacing: LottaPawsTheme.spacingSM) {
            // Name - the star of the show
            Text(title)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
            
            // Metadata pills
            HStack(spacing: LottaPawsTheme.spacingSM) {
                // Species + Member Type pill
                MetadataPill(
                    emoji: speciesEmoji,
                    text: memberType.capitalized
                )
                
                // Birthday pill (if available)
                if let birthday = birthday {
                    MetadataPill(
                        emoji: "🎂",
                        text: birthday
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LottaPawsTheme.spacingLG)
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
    
    private var speciesEmoji: String {
        guard let species = species?.lowercased() else { return "🐾" }
        
        switch species {
        case "rabbit": return "🐰"
        case "cat": return "🐱"
        case "dog": return "🐶"
        case "bear": return "🐻"
        case "squirrel": return "🐿️"
        case "mouse": return "🐭"
        case "elephant": return "🐘"
        case "deer": return "🦌"
        case "fox": return "🦊"
        case "hedgehog": return "🦔"
        case "koala": return "🐨"
        case "monkey": return "🐵"
        case "otter": return "🦦"
        case "owl": return "🦉"
        case "panda": return "🐼"
        case "penguin": return "🐧"
        case "pig": return "🐷"
        case "sheep", "lamb": return "🐑"
        case "kangaroo": return "🦘"
        case "lion": return "🦁"
        case "tiger": return "🐯"
        case "wolf": return "🐺"
        case "beaver": return "🦫"
        case "hamster": return "🐹"
        case "raccoon": return "🦝"
        case "skunk": return "🦨"
        case "chipmunk": return "🐿️"
        case "duck": return "🦆"
        case "goat": return "🐐"
        case "cow": return "🐮"
        case "horse": return "🐴"
        case "frog": return "🐸"
        default: return "🐾"
        }
    }
}

// MARK: - Metadata Pill

private struct MetadataPill: View {
    let emoji: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Text(emoji)
                .font(.system(size: 14))
            Text(text)
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundColor(.white)
        .padding(.horizontal, LottaPawsTheme.spacingSM)
        .padding(.vertical, LottaPawsTheme.spacingXS)
        .background(Color.white.opacity(0.2))
        .clipShape(Capsule())
    }
}

// MARK: - Convenience Initializers

extension VariantHeroImage {
    /// Initialize from API response (VariantResponse + CritterInfo)
    /// Initialize from API response (VariantResponse + CritterInfo)
    init(
        variant: VariantResponse,
        critter: CritterInfo,
        onExpandTap: @escaping () -> Void
    ) {
        self.localImagePath = nil
        self.remoteImageURL = variant.imageUrl
        self.title = critter.name
        self.memberType = critter.memberType
        self.birthday = critter.birthday
        self.species = critter.species
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
        self.memberType = ownedVariant.memberType
        self.birthday = ownedVariant.formattedBirthday
        self.species = ownedVariant.familySpecies
        self.onExpandTap = onExpandTap
    }
}

#Preview("With Metadata") {
    VariantHeroImage(
        localImagePath: nil,
        remoteImageURL: "https://example.com/image.jpg",
        title: "Flora Rabbit",
        memberType: "Babies",
        birthday: "December 3",
        species: "rabbit",
        onExpandTap: {}
    )
}

#Preview("Placeholder") {
    VariantHeroImage(
        localImagePath: nil,
        remoteImageURL: nil,
        title: "Flora Rabbit",
        memberType: "Babies",
        birthday: nil,
        species: nil,
        onExpandTap: {}
    )
}
