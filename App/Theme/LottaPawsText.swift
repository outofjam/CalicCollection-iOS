import SwiftUI

// MARK: - Text Styles

/// Text style presets matching the LottaPaws design system
enum LPTextStyle {
    case largeTitle      // Screen titles, big numbers
    case title1          // Section headers
    case title2          // Card titles
    case title3          // List item titles
    case headline        // Emphasized text
    case body            // Regular body text
    case callout         // Slightly smaller body
    case subheadline     // Secondary info
    case footnote        // Tertiary info, timestamps
    case caption         // Small labels
    case caption2        // Extra small
    
    var font: Font {
        switch self {
        case .largeTitle: return .system(size: 34, weight: .bold)
        case .title1: return .system(size: 28, weight: .bold)
        case .title2: return .system(size: 22, weight: .bold)
        case .title3: return .system(size: 20, weight: .semibold)
        case .headline: return .system(size: 17, weight: .semibold)
        case .body: return .system(size: 17, weight: .regular)
        case .callout: return .system(size: 16, weight: .regular)
        case .subheadline: return .system(size: 15, weight: .regular)
        case .footnote: return .system(size: 13, weight: .regular)
        case .caption: return .system(size: 12, weight: .medium)
        case .caption2: return .system(size: 11, weight: .regular)
        }
    }
    
    var defaultColor: Color {
        switch self {
        case .largeTitle, .title1, .title2, .title3, .headline, .body:
            return .textPrimary
        case .callout, .subheadline:
            return .textSecondary
        case .footnote, .caption, .caption2:
            return .textTertiary
        }
    }
}

// MARK: - Text View Modifier

struct LPTextStyleModifier: ViewModifier {
    let style: LPTextStyle
    var color: Color?
    
    func body(content: Content) -> some View {
        content
            .font(style.font)
            .foregroundColor(color ?? style.defaultColor)
    }
}

extension View {
    func lpTextStyle(_ style: LPTextStyle, color: Color? = nil) -> some View {
        modifier(LPTextStyleModifier(style: style, color: color))
    }
}

// MARK: - Styled Text Components

/// Pre-styled text components for common use cases
struct LPText: View {
    let text: String
    let style: LPTextStyle
    var color: Color?
    
    init(_ text: String, style: LPTextStyle = .body, color: Color? = nil) {
        self.text = text
        self.style = style
        self.color = color
    }
    
    var body: some View {
        Text(text)
            .lpTextStyle(style, color: color)
    }
}

// MARK: - Section Header

/// Styled section header for lists
struct LPSectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionLabel: String = "See All"
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            if let action = action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primaryPink)
                }
            }
        }
        .padding(.horizontal, LottaPawsTheme.spacingLG)
        .padding(.vertical, LottaPawsTheme.spacingSM)
    }
}

// MARK: - Empty State

/// Styled empty state view
struct LPEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var buttonTitle: String? = nil
    var buttonAction: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: LottaPawsTheme.spacingLG) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(LinearGradient.lottaGradient)
            
            VStack(spacing: LottaPawsTheme.spacingSM) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Text(message)
                    .font(.system(size: 15))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, LottaPawsTheme.spacingXL)
            }
            
            if let buttonTitle = buttonTitle, let action = buttonAction {
                Button(buttonTitle, action: action)
                    .buttonStyle(.primary)
                    .padding(.top, LottaPawsTheme.spacingSM)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(LottaPawsTheme.spacingXL)
    }
}

// MARK: - Info Row

/// Key-value info row for detail views
struct LPInfoRow: View {
    let label: String
    let value: String
    var valueColor: Color = .textPrimary
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(valueColor)
        }
        .padding(.vertical, LottaPawsTheme.spacingSM)
    }
}

// MARK: - Stat View

/// Statistic display with label
struct LPStatView: View {
    let value: String
    let label: String
    var valueColor: Color = .textPrimary
    var alignment: HorizontalAlignment = .center
    
    var body: some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(valueColor)
            
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.textSecondary)
        }
    }
}

/// Horizontal stat group
struct LPStatGroup: View {
    let stats: [(value: String, label: String)]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(stats.enumerated()), id: \.offset) { index, stat in
                if index > 0 {
                    Divider()
                        .frame(height: 40)
                        .padding(.horizontal, LottaPawsTheme.spacingLG)
                }
                
                LPStatView(value: stat.value, label: stat.label)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, LottaPawsTheme.spacingMD)
    }
}

// MARK: - Usage Examples
/*
 
 // Text with style
 Text("Hello")
     .lpTextStyle(.title1)
 
 // Or use LPText directly
 LPText("Collection", style: .title2)
 LPText("5 items", style: .caption, color: .textSecondary)
 
 // Section header
 LPSectionHeader(title: "My Collection")
 LPSectionHeader(title: "Families", action: { }, actionLabel: "View All")
 
 // Empty state
 LPEmptyState(
     icon: "heart.slash",
     title: "No Wishlist Items",
     message: "Browse the catalog and add items to your wishlist!",
     buttonTitle: "Start Browsing",
     buttonAction: { }
 )
 
 // Info row
 LPInfoRow(label: "Release Year", value: "2023")
 LPInfoRow(label: "Status", value: "In Collection", valueColor: .successGreen)
 
 // Stats
 LPStatView(value: "42", label: "Owned")
 
 // Stat group
 LPStatGroup(stats: [
     (value: "42", label: "Owned"),
     (value: "8", label: "Wishlist"),
     (value: "85%", label: "Complete")
 ])
 
 */
