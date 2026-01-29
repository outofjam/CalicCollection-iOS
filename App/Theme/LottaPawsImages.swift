import SwiftUI

// MARK: - Grid Item Card

/// Card for displaying a critter/variant in a grid
struct LPGridItem: View {
    let imageURL: URL?
    let title: String
    var subtitle: String? = nil
    var badge: String? = nil
    var badgeColor: Color = .successGreen
    var isOwned: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                // Image container
                ZStack(alignment: .topTrailing) {
                    // Image
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.backgroundSecondary)
                                .overlay(
                                    ProgressView()
                                        .tint(.primaryPink)
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Rectangle()
                                .fill(Color.backgroundSecondary)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 24))
                                        .foregroundColor(.textTertiary)
                                )
                        @unknown default:
                            Rectangle()
                                .fill(Color.backgroundSecondary)
                        }
                    }
                    .frame(height: 140)
                    .clipped()
                    
                    // Badge
                    if let badge = badge {
                        LPFilledBadge(
                            text: badge,
                            backgroundColor: badgeColor,
                            size: .small
                        )
                        .padding(LottaPawsTheme.spacingSM)
                    }
                    
                    // Owned checkmark
                    if isOwned && badge == nil {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.successGreen)
                            .background(Circle().fill(Color.white).padding(2))
                            .padding(LottaPawsTheme.spacingSM)
                    }
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                            .lineLimit(1)
                    }
                }
                .padding(LottaPawsTheme.spacingSM)
            }
            .background(Color.backgroundPrimary)
            .cornerRadius(LottaPawsTheme.radiusMD)
            .shadow(
                color: LottaPawsTheme.shadowSoft.color,
                radius: LottaPawsTheme.shadowSoft.radius,
                x: LottaPawsTheme.shadowSoft.x,
                y: LottaPawsTheme.shadowSoft.y
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Grid Item with Local Image

/// Grid item that supports local cached images
struct LPGridItemCached: View {
    let localImage: UIImage?
    let remoteURL: URL?
    let title: String
    var subtitle: String? = nil
    var badge: String? = nil
    var badgeColor: Color = .successGreen
    var isOwned: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                // Image container
                ZStack(alignment: .topTrailing) {
                    // Image - prefer local, fallback to remote
                    if let localImage = localImage {
                        Image(uiImage: localImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 140)
                            .clipped()
                    } else {
                        AsyncImage(url: remoteURL) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color.backgroundSecondary)
                                    .overlay(ProgressView().tint(.primaryPink))
                            case .success(let image):
                                image.resizable().aspectRatio(contentMode: .fill)
                            case .failure:
                                Rectangle()
                                    .fill(Color.backgroundSecondary)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundColor(.textTertiary)
                                    )
                            @unknown default:
                                Rectangle().fill(Color.backgroundSecondary)
                            }
                        }
                        .frame(height: 140)
                        .clipped()
                    }
                    
                    // Badge
                    if let badge = badge {
                        LPFilledBadge(text: badge, backgroundColor: badgeColor, size: .small)
                            .padding(LottaPawsTheme.spacingSM)
                    }
                    
                    // Owned checkmark
                    if isOwned && badge == nil {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.successGreen)
                            .background(Circle().fill(Color.white).padding(2))
                            .padding(LottaPawsTheme.spacingSM)
                    }
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                            .lineLimit(1)
                    }
                }
                .padding(LottaPawsTheme.spacingSM)
            }
            .background(Color.backgroundPrimary)
            .cornerRadius(LottaPawsTheme.radiusMD)
            .shadow(
                color: LottaPawsTheme.shadowSoft.color,
                radius: LottaPawsTheme.shadowSoft.radius,
                x: LottaPawsTheme.shadowSoft.x,
                y: LottaPawsTheme.shadowSoft.y
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - List Row Item

/// Row item for displaying a critter/variant in a list
struct LPListItem: View {
    let imageURL: URL?
    let title: String
    var subtitle: String? = nil
    var memberType: String? = nil
    var isOwned: Bool = false
    var showChevron: Bool = true
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: LottaPawsTheme.spacingMD) {
                // Thumbnail
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        Rectangle()
                            .fill(Color.backgroundSecondary)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.textTertiary)
                            )
                    }
                }
                .frame(width: 56, height: 56)
                .cornerRadius(LottaPawsTheme.radiusSM)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: LottaPawsTheme.spacingSM) {
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(.system(size: 13))
                                .foregroundColor(.textSecondary)
                                .lineLimit(1)
                        }
                        
                        if let memberType = memberType {
                            MemberTypeBadge(memberType: memberType, size: .small)
                        }
                    }
                }
                
                Spacer()
                
                // Status / Chevron
                HStack(spacing: LottaPawsTheme.spacingSM) {
                    if isOwned {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.successGreen)
                    }
                    
                    if showChevron {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.textTertiary)
                    }
                }
            }
            .padding(.vertical, LottaPawsTheme.spacingSM)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Hero Image

/// Large hero image with gradient overlay for detail views
struct LPHeroImage: View {
    let imageURL: URL?
    var localImage: UIImage? = nil
    var height: CGFloat = 300
    var showExpandButton: Bool = true
    var onExpand: (() -> Void)? = nil
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Image
            if let localImage = localImage {
                Image(uiImage: localImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: height)
            } else {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    default:
                        Rectangle()
                            .fill(LinearGradient.lottaGradient.opacity(0.3))
                            .overlay(
                                ProgressView()
                                    .tint(.primaryPink)
                            )
                    }
                }
                .frame(maxHeight: height)
            }
            
            // Expand button
            if showExpandButton, let onExpand = onExpand {
                Button(action: onExpand) {
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
        .frame(maxWidth: .infinity)
        .background(Color.backgroundSecondary)
    }
}

// MARK: - Avatar / Thumbnail

/// Circular avatar image
struct LPAvatar: View {
    let imageURL: URL?
    var size: CGFloat = 40
    var borderColor: Color = .primaryPink
    var showBorder: Bool = false
    
    var body: some View {
        AsyncImage(url: imageURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(contentMode: .fill)
            default:
                Circle()
                    .fill(LinearGradient.lottaGradient.opacity(0.5))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            showBorder ?
            Circle().stroke(borderColor, lineWidth: 2) :
            nil
        )
    }
}

// MARK: - Usage Examples
/*
 
 // Grid item
 LPGridItem(
     imageURL: URL(string: "..."),
     title: "Stella Hopscotch",
     subtitle: "Rabbit Family",
     isOwned: true
 ) {
     // Action
 }
 
 // Grid item with badge
 LPGridItem(
     imageURL: URL(string: "..."),
     title: "Limited Edition",
     badge: "Rare",
     badgeColor: .warningYellow
 ) {
     // Action
 }
 
 // List item
 LPListItem(
     imageURL: URL(string: "..."),
     title: "Freya Chocolate",
     subtitle: "Chocolate Rabbit Family",
     memberType: "Mother",
     isOwned: true
 ) {
     // Action
 }
 
 // Hero image
 LPHeroImage(
     imageURL: URL(string: "..."),
     onExpand: { showFullScreen = true }
 )
 
 // Avatar
 LPAvatar(imageURL: URL(string: "..."), size: 60, showBorder: true)
 
 */
