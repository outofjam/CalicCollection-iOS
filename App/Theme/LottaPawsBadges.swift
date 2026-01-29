import SwiftUI

// MARK: - Badge Components

/// Generic pill badge
struct LPBadge: View {
    let text: String
    var color: Color = .primaryPink
    var size: BadgeSize = .medium
    
    enum BadgeSize {
        case small, medium, large
        
        var font: Font {
            switch self {
            case .small: return .system(size: 10, weight: .semibold)
            case .medium: return .system(size: 12, weight: .semibold)
            case .large: return .system(size: 14, weight: .semibold)
            }
        }
        
        var horizontalPadding: CGFloat {
            switch self {
            case .small: return 6
            case .medium: return 8
            case .large: return 10
            }
        }
        
        var verticalPadding: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return 4
            case .large: return 6
            }
        }
    }
    
    var body: some View {
        Text(text)
            .font(size.font)
            .foregroundColor(color)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
            )
    }
}

/// Filled badge (solid background)
struct LPFilledBadge: View {
    let text: String
    var backgroundColor: Color = .primaryPink
    var textColor: Color = .white
    var size: LPBadge.BadgeSize = .medium
    
    var body: some View {
        Text(text)
            .font(size.font)
            .foregroundColor(textColor)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .background(
                Capsule()
                    .fill(backgroundColor)
            )
    }
}

// MARK: - Member Type Badge

/// Badge for critter member types (Father, Mother, Sister, Brother, Baby, etc.)
struct MemberTypeBadge: View {
    let memberType: String
    var size: LPBadge.BadgeSize = .medium
    
    private var config: MemberTypeConfig {
        MemberTypeConfig.forType(memberType)
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon = config.icon {
                Image(systemName: icon)
                    .font(.system(size: size == .small ? 8 : (size == .medium ? 10 : 12)))
            }
            Text(memberType)
        }
        .font(size.font)
        .foregroundColor(config.color)
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(
            Capsule()
                .fill(config.color.opacity(0.15))
        )
    }
}

/// Configuration for member type colors and icons
struct MemberTypeConfig {
    let color: Color
    let icon: String?
    
    static func forType(_ type: String) -> MemberTypeConfig {
        switch type.lowercased() {
        // Parents
        case "father", "dad", "grandfather", "grandpa":
            return MemberTypeConfig(color: .secondaryBlueDark, icon: nil)
        case "mother", "mom", "grandmother", "grandma":
            return MemberTypeConfig(color: .primaryPink, icon: nil)
            
        // Siblings
        case "brother", "older brother", "big brother":
            return MemberTypeConfig(color: .secondaryBlue, icon: nil)
        case "sister", "older sister", "big sister":
            return MemberTypeConfig(color: .accentBlush, icon: nil)
            
        // Babies & Young ones
        case "baby", "baby boy", "baby girl":
            return MemberTypeConfig(color: .warningYellow, icon: "star.fill")
        case "infant", "baby infant":
            return MemberTypeConfig(color: Color(red: 0.95, green: 0.75, blue: 0.85), icon: "heart.fill")
        case "toddler":
            return MemberTypeConfig(color: .successGreen, icon: nil)
            
        // Twins/Multiples
        case "twin", "twins", "twin boy", "twin girl":
            return MemberTypeConfig(color: Color(red: 0.75, green: 0.65, blue: 0.90), icon: nil)
        case "triplet", "triplets":
            return MemberTypeConfig(color: Color(red: 0.70, green: 0.80, blue: 0.75), icon: nil)
            
        // Others
        case "uncle":
            return MemberTypeConfig(color: Color(red: 0.55, green: 0.65, blue: 0.75), icon: nil)
        case "aunt":
            return MemberTypeConfig(color: Color(red: 0.85, green: 0.65, blue: 0.75), icon: nil)
        case "cousin":
            return MemberTypeConfig(color: Color(red: 0.70, green: 0.75, blue: 0.65), icon: nil)
            
        default:
            return MemberTypeConfig(color: .textSecondary, icon: nil)
        }
    }
}

// MARK: - Status Badge

/// Badge for collection/wishlist status
struct StatusBadge: View {
    enum Status {
        case collection
        case wishlist
        case owned
        case missing
        
        var text: String {
            switch self {
            case .collection: return "In Collection"
            case .wishlist: return "Wishlist"
            case .owned: return "Owned"
            case .missing: return "Missing"
            }
        }
        
        var color: Color {
            switch self {
            case .collection, .owned: return .successGreen
            case .wishlist: return .primaryPink
            case .missing: return .textTertiary
            }
        }
        
        var icon: String {
            switch self {
            case .collection, .owned: return "checkmark.circle.fill"
            case .wishlist: return "heart.fill"
            case .missing: return "circle.dashed"
            }
        }
    }
    
    let status: Status
    var showIcon: Bool = true
    var size: LPBadge.BadgeSize = .medium
    
    var body: some View {
        HStack(spacing: 4) {
            if showIcon {
                Image(systemName: status.icon)
                    .font(.system(size: size == .small ? 8 : (size == .medium ? 10 : 12)))
            }
            Text(status.text)
        }
        .font(size.font)
        .foregroundColor(status.color)
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(
            Capsule()
                .fill(status.color.opacity(0.15))
        )
    }
}

// MARK: - Count Badge

/// Numeric badge (e.g., for counts, notifications)
struct CountBadge: View {
    let count: Int
    var color: Color = .primaryPink
    
    var body: some View {
        Text("\(count)")
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
            .frame(minWidth: 18, minHeight: 18)
            .padding(.horizontal, 4)
            .background(
                Capsule()
                    .fill(color)
            )
    }
}

// MARK: - Family Completion Badge

/// Badge showing family completion progress
struct FamilyCompletionBadge: View {
    let owned: Int
    let total: Int
    
    private var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(owned) / Double(total)
    }
    
    private var color: Color {
        switch percentage {
        case 1.0: return .successGreen
        case 0.5..<1.0: return .warningYellow
        default: return .textTertiary
        }
    }
    
    private var icon: String {
        switch percentage {
        case 1.0: return "checkmark.circle.fill"
        case 0.5..<1.0: return "circle.bottomhalf.filled"
        default: return "circle.dashed"
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text("\(owned)/\(total)")
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
    }
}

// MARK: - Usage Examples
/*
 
 // Generic badge
 LPBadge(text: "New", color: .successGreen)
 LPBadge(text: "Rare", color: .warningYellow, size: .small)
 
 // Filled badge
 LPFilledBadge(text: "Featured", backgroundColor: .primaryPink)
 
 // Member type badge
 MemberTypeBadge(memberType: "Mother")
 MemberTypeBadge(memberType: "Baby", size: .small)
 MemberTypeBadge(memberType: "Father")
 
 // Status badges
 StatusBadge(status: .collection)
 StatusBadge(status: .wishlist, showIcon: false)
 
 // Count badge
 CountBadge(count: 5)
 CountBadge(count: 12, color: .secondaryBlue)
 
 // Family completion
 FamilyCompletionBadge(owned: 3, total: 5)
 FamilyCompletionBadge(owned: 5, total: 5) // Shows green checkmark
 
 */
