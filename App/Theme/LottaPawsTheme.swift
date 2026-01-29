import SwiftUI

// MARK: - LottaPaws Theme
// Drop this file + LottaPawsColors.swift into your project
// Then apply .lottaPawsStyle() to your root view

// MARK: - App-Wide Theme Configuration

struct LottaPawsTheme {
    
    // MARK: - Spacing
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 12
    static let spacingLG: CGFloat = 16
    static let spacingXL: CGFloat = 24
    static let spacingXXL: CGFloat = 32
    
    // MARK: - Corner Radius
    static let radiusSM: CGFloat = 8
    static let radiusMD: CGFloat = 12
    static let radiusLG: CGFloat = 16
    static let radiusXL: CGFloat = 20
    static let radiusFull: CGFloat = 999
    
    // MARK: - Shadows
    static let shadowSoft = Shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    static let shadowMedium = Shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 4)
    
    // MARK: - Animation
    static let animationSpring = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let animationQuick = Animation.easeOut(duration: 0.2)
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Root View Modifier
// Apply this to your root ContentView to set app-wide styling

struct LottaPawsStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .tint(.primaryPink)
            .background(Color.backgroundPrimary)
    }
}

extension View {
    func lottaPawsStyle() -> some View {
        modifier(LottaPawsStyleModifier())
    }
}

// MARK: - Navigation Bar Appearance
// Call this in your App init or ContentView onAppear

func configureLottaPawsAppearance() {
    // Navigation Bar - Standard (when scrolled)
    let navAppearance = UINavigationBarAppearance()
    navAppearance.configureWithDefaultBackground()
    navAppearance.titleTextAttributes = [
        .foregroundColor: UIColor(Color.textPrimary),
        .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
    ]
    navAppearance.largeTitleTextAttributes = [
        .foregroundColor: UIColor(Color.textPrimary),
        .font: UIFont.systemFont(ofSize: 34, weight: .bold)
    ]
    
    // Scroll edge appearance (when at top - transparent/blur)
    let scrollEdgeAppearance = UINavigationBarAppearance()
    scrollEdgeAppearance.configureWithTransparentBackground()
    scrollEdgeAppearance.largeTitleTextAttributes = [
        .foregroundColor: UIColor(Color.textPrimary),
        .font: UIFont.systemFont(ofSize: 34, weight: .bold)
    ]
    
    UINavigationBar.appearance().standardAppearance = navAppearance
    UINavigationBar.appearance().scrollEdgeAppearance = scrollEdgeAppearance
    UINavigationBar.appearance().compactAppearance = navAppearance
    UINavigationBar.appearance().tintColor = UIColor(Color.primaryPink)
    
    // Tab Bar
    let tabAppearance = UITabBarAppearance()
    tabAppearance.configureWithDefaultBackground()
    
    // Unselected tab items
    tabAppearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.textTertiary)
    tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
        .foregroundColor: UIColor(Color.textTertiary)
    ]
    
    // Selected tab items
    tabAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.primaryPink)
    tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
        .foregroundColor: UIColor(Color.primaryPink)
    ]
    
    UITabBar.appearance().standardAppearance = tabAppearance
    UITabBar.appearance().scrollEdgeAppearance = tabAppearance
}
