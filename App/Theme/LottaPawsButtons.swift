import SwiftUI

// MARK: - Button Styles

/// Primary button - pink filled, for main actions like "Add to Collection"
struct PrimaryButtonStyle: ButtonStyle {
    var isFullWidth: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, LottaPawsTheme.spacingLG)
            .padding(.vertical, LottaPawsTheme.spacingMD)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: LottaPawsTheme.radiusMD)
                    .fill(configuration.isPressed ? Color.primaryPinkDark : Color.primaryPink)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(LottaPawsTheme.animationQuick, value: configuration.isPressed)
    }
}

/// Secondary button - outlined, for secondary actions
struct SecondaryButtonStyle: ButtonStyle {
    var isFullWidth: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(configuration.isPressed ? .primaryPinkDark : .primaryPink)
            .padding(.horizontal, LottaPawsTheme.spacingLG)
            .padding(.vertical, LottaPawsTheme.spacingMD)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: LottaPawsTheme.radiusMD)
                    .stroke(Color.primaryPink, lineWidth: 1.5)
                    .background(
                        RoundedRectangle(cornerRadius: LottaPawsTheme.radiusMD)
                            .fill(configuration.isPressed ? Color.primaryPinkLight.opacity(0.3) : Color.clear)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(LottaPawsTheme.animationQuick, value: configuration.isPressed)
    }
}

/// Tertiary button - text only, for less prominent actions
struct TertiaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(configuration.isPressed ? .primaryPinkDark : .primaryPink)
            .padding(.horizontal, LottaPawsTheme.spacingSM)
            .padding(.vertical, LottaPawsTheme.spacingXS)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(LottaPawsTheme.animationQuick, value: configuration.isPressed)
    }
}

/// Soft button - lightly filled background, for contextual actions
struct SoftButtonStyle: ButtonStyle {
    var color: Color = .primaryPink
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, LottaPawsTheme.spacingMD)
            .padding(.vertical, LottaPawsTheme.spacingSM)
            .background(
                RoundedRectangle(cornerRadius: LottaPawsTheme.radiusSM)
                    .fill(color.opacity(configuration.isPressed ? 0.2 : 0.12))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(LottaPawsTheme.animationQuick, value: configuration.isPressed)
    }
}

/// Icon button - circular, for icon-only buttons
struct IconButtonStyle: ButtonStyle {
    var size: CGFloat = 44
    var filled: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(filled ? .white : .primaryPink)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(filled ? 
                          (configuration.isPressed ? Color.primaryPinkDark : Color.primaryPink) :
                          (configuration.isPressed ? Color.primaryPinkLight.opacity(0.5) : Color.primaryPinkLight.opacity(0.3))
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(LottaPawsTheme.animationQuick, value: configuration.isPressed)
    }
}

// MARK: - Button Style Extensions

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
    static var primaryFullWidth: PrimaryButtonStyle { PrimaryButtonStyle(isFullWidth: true) }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
    static var secondaryFullWidth: SecondaryButtonStyle { SecondaryButtonStyle(isFullWidth: true) }
}

extension ButtonStyle where Self == TertiaryButtonStyle {
    static var tertiary: TertiaryButtonStyle { TertiaryButtonStyle() }
}

extension ButtonStyle where Self == SoftButtonStyle {
    static var soft: SoftButtonStyle { SoftButtonStyle() }
    static func soft(color: Color) -> SoftButtonStyle { SoftButtonStyle(color: color) }
}

extension ButtonStyle where Self == IconButtonStyle {
    static var icon: IconButtonStyle { IconButtonStyle() }
    static var iconFilled: IconButtonStyle { IconButtonStyle(filled: true) }
    static func icon(size: CGFloat) -> IconButtonStyle { IconButtonStyle(size: size) }
}

// MARK: - Usage Examples
/*
 
 // Primary button
 Button("Add to Collection") { }
     .buttonStyle(.primary)
 
 // Full width primary
 Button("Save Changes") { }
     .buttonStyle(.primaryFullWidth)
 
 // Secondary (outlined)
 Button("Add to Wishlist") { }
     .buttonStyle(.secondary)
 
 // Text-only tertiary
 Button("Skip") { }
     .buttonStyle(.tertiary)
 
 // Soft background
 Button("Edit") { }
     .buttonStyle(.soft)
 
 // Soft with custom color
 Button("Delete") { }
     .buttonStyle(.soft(color: .errorRed))
 
 // Icon button
 Button { } label: {
     Image(systemName: "heart.fill")
 }
 .buttonStyle(.icon)
 
 // Filled icon button
 Button { } label: {
     Image(systemName: "plus")
 }
 .buttonStyle(.iconFilled)
 
 */
