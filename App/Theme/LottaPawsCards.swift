import SwiftUI

// MARK: - Card Components

/// Standard card container with soft shadow
struct LPCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = LottaPawsTheme.spacingLG
    
    init(padding: CGFloat = LottaPawsTheme.spacingLG, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(Color.backgroundPrimary)
            .cornerRadius(LottaPawsTheme.radiusMD)
            .shadow(
                color: LottaPawsTheme.shadowSoft.color,
                radius: LottaPawsTheme.shadowSoft.radius,
                x: LottaPawsTheme.shadowSoft.x,
                y: LottaPawsTheme.shadowSoft.y
            )
    }
}

/// Soft background card (no shadow, tinted background)
struct LPSoftCard<Content: View>: View {
    let content: Content
    var backgroundColor: Color = .backgroundSecondary
    var padding: CGFloat = LottaPawsTheme.spacingLG
    
    init(
        backgroundColor: Color = .backgroundSecondary,
        padding: CGFloat = LottaPawsTheme.spacingLG,
        @ViewBuilder content: () -> Content
    ) {
        self.backgroundColor = backgroundColor
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(LottaPawsTheme.radiusMD)
    }
}

/// Bordered card with subtle border
struct LPBorderedCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = LottaPawsTheme.spacingLG
    
    init(padding: CGFloat = LottaPawsTheme.spacingLG, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(Color.backgroundPrimary)
            .cornerRadius(LottaPawsTheme.radiusMD)
            .overlay(
                RoundedRectangle(cornerRadius: LottaPawsTheme.radiusMD)
                    .stroke(Color.borderColor, lineWidth: 1)
            )
    }
}

/// Gradient card for featured/hero sections
struct LPGradientCard<Content: View>: View {
    let content: Content
    var gradient: LinearGradient = .lottaGradient
    var padding: CGFloat = LottaPawsTheme.spacingLG
    
    init(
        gradient: LinearGradient = .lottaGradient,
        padding: CGFloat = LottaPawsTheme.spacingLG,
        @ViewBuilder content: () -> Content
    ) {
        self.gradient = gradient
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(gradient)
            .cornerRadius(LottaPawsTheme.radiusLG)
            .shadow(
                color: LottaPawsTheme.shadowMedium.color,
                radius: LottaPawsTheme.shadowMedium.radius,
                x: LottaPawsTheme.shadowMedium.x,
                y: LottaPawsTheme.shadowMedium.y
            )
    }
}

// MARK: - View Modifiers for Cards

struct CardModifier: ViewModifier {
    var padding: CGFloat = LottaPawsTheme.spacingLG
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.backgroundPrimary)
            .cornerRadius(LottaPawsTheme.radiusMD)
            .shadow(
                color: LottaPawsTheme.shadowSoft.color,
                radius: LottaPawsTheme.shadowSoft.radius,
                x: LottaPawsTheme.shadowSoft.x,
                y: LottaPawsTheme.shadowSoft.y
            )
    }
}

struct SoftCardModifier: ViewModifier {
    var backgroundColor: Color = .backgroundSecondary
    var padding: CGFloat = LottaPawsTheme.spacingLG
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(LottaPawsTheme.radiusMD)
    }
}

extension View {
    func cardStyle(padding: CGFloat = LottaPawsTheme.spacingLG) -> some View {
        modifier(CardModifier(padding: padding))
    }
    
    func softCardStyle(
        backgroundColor: Color = .backgroundSecondary,
        padding: CGFloat = LottaPawsTheme.spacingLG
    ) -> some View {
        modifier(SoftCardModifier(backgroundColor: backgroundColor, padding: padding))
    }
}

// MARK: - List Row Components

/// Styled list row for settings/menu items
struct LPListRow<Leading: View, Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    let leading: Leading
    let trailing: Trailing
    var action: (() -> Void)? = nil
    
    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leading = leading()
        self.trailing = trailing()
        self.action = action
    }
    
    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: LottaPawsTheme.spacingMD) {
                leading
                    .frame(width: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.textPrimary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(.textSecondary)
                    }
                }
                
                Spacer()
                
                trailing
            }
            .padding(.vertical, LottaPawsTheme.spacingMD)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

// Convenience initializers
extension LPListRow where Leading == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: () -> Trailing,
        action: (() -> Void)? = nil
    ) {
        self.init(title: title, subtitle: subtitle, leading: { EmptyView() }, trailing: trailing, action: action)
    }
}

extension LPListRow where Trailing == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder leading: () -> Leading,
        action: (() -> Void)? = nil
    ) {
        self.init(title: title, subtitle: subtitle, leading: leading, trailing: { EmptyView() }, action: action)
    }
}

extension LPListRow where Leading == EmptyView, Trailing == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.init(title: title, subtitle: subtitle, leading: { EmptyView() }, trailing: { EmptyView() }, action: action)
    }
}

// MARK: - Divider

struct LPDivider: View {
    var color: Color = .dividerColor
    var height: CGFloat = 1
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: height)
    }
}

// MARK: - Usage Examples
/*
 
 // Standard card
 LPCard {
     VStack {
         Text("My Content")
     }
 }
 
 // Or use the modifier
 VStack {
     Text("My Content")
 }
 .cardStyle()
 
 // Soft background card
 LPSoftCard {
     Text("Subtle background")
 }
 
 // Gradient card for hero sections
 LPGradientCard {
     VStack {
         Text("Featured!")
             .foregroundColor(.white)
     }
 }
 
 // List row with icon and chevron
 LPListRow(
     title: "Sync Data",
     subtitle: "Last synced 2 hours ago",
     leading: {
         Image(systemName: "arrow.triangle.2.circlepath")
             .foregroundColor(.primaryPink)
     },
     trailing: {
         Image(systemName: "chevron.right")
             .foregroundColor(.textTertiary)
             .font(.system(size: 14, weight: .semibold))
     },
     action: { print("Tapped!") }
 )
 
 // Simple divider
 LPDivider()
 
 */
