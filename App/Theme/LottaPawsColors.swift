import SwiftUI

// MARK: - LottaPaws Color Palette
// Adaptive colors for light and dark mode

extension Color {
    
    // MARK: - Gradient Colors
    // Use these for header backgrounds, hero sections
    
    static let gradientPinkStart = Color(red: 0.941, green: 0.718, blue: 0.843)  // #F0B7D7
    static let gradientPinkEnd = Color(red: 0.957, green: 0.784, blue: 0.875)    // #F4C8DF
    static let gradientBlueStart = Color(red: 0.639, green: 0.757, blue: 0.953)  // #A3C1F3
    static let gradientBlueEnd = Color(red: 0.765, green: 0.741, blue: 0.914)    // #C3BDE9
    
    // MARK: - Primary Colors (Adaptive)
    // Main actions, buttons, key UI elements
    
    static let primaryPink = Color(
        light: Color(red: 0.910, green: 0.643, blue: 0.788),      // #E8A4C9
        dark: Color(red: 0.949, green: 0.706, blue: 0.835)        // Brighter for dark mode
    )
    
    static let primaryPinkLight = Color(
        light: Color(red: 0.957, green: 0.820, blue: 0.898),      // #F4D1E5
        dark: Color(red: 0.400, green: 0.280, blue: 0.340)        // Muted for dark backgrounds
    )
    
    static let primaryPinkDark = Color(
        light: Color(red: 0.788, green: 0.482, blue: 0.639),      // #C97BA3
        dark: Color(red: 0.988, green: 0.769, blue: 0.878)        // Brighter for dark mode
    )
    
    // MARK: - Secondary Colors (Adaptive)
    // Secondary actions, less prominent elements
    
    static let secondaryBlue = Color(
        light: Color(red: 0.659, green: 0.765, blue: 0.949),      // #A8C3F2
        dark: Color(red: 0.718, green: 0.808, blue: 0.969)        // Slightly brighter
    )
    
    static let secondaryBlueLight = Color(
        light: Color(red: 0.784, green: 0.851, blue: 0.973),      // #C8D9F8
        dark: Color(red: 0.300, green: 0.360, blue: 0.480)        // Muted for dark backgrounds
    )
    
    static let secondaryBlueDark = Color(
        light: Color(red: 0.478, green: 0.608, blue: 0.831),      // #7A9BD4
        dark: Color(red: 0.600, green: 0.718, blue: 0.918)        // Brighter for dark mode
    )
    
    // MARK: - Accent Colors
    // Highlights, badges, special callouts
    
    static let accentBlush = Color(red: 0.949, green: 0.808, blue: 0.855)        // #F2CEDA
    static let accentWarm = Color(red: 1.000, green: 0.706, blue: 0.706)         // #FFB4B4
    
    // MARK: - Background Colors (Adaptive)
    
    static let backgroundPrimary = Color(
        light: Color.white,
        dark: Color(red: 0.110, green: 0.110, blue: 0.118)        // System dark background
    )
    
    static let backgroundSecondary = Color(
        light: Color(red: 1.000, green: 0.973, blue: 0.980),      // #FFF8FA - soft pink tint
        dark: Color(red: 0.173, green: 0.173, blue: 0.180)        // Elevated dark surface
    )
    
    static let backgroundTertiary = Color(
        light: Color(red: 0.973, green: 0.957, blue: 0.976),      // #F8F4F9
        dark: Color(red: 0.227, green: 0.227, blue: 0.235)        // Higher elevation
    )
    
    // MARK: - Text Colors (Adaptive)
    
    static let textPrimary = Color(
        light: Color(red: 0.290, green: 0.227, blue: 0.259),      // #4A3A42 - dark brown
        dark: Color(red: 0.980, green: 0.965, blue: 0.973)        // Almost white with warm tint
    )
    
    static let textSecondary = Color(
        light: Color(red: 0.478, green: 0.416, blue: 0.447),      // #7A6A72
        dark: Color(red: 0.780, green: 0.745, blue: 0.765)        // Lighter for dark mode
    )
    
    static let textTertiary = Color(
        light: Color(red: 0.663, green: 0.604, blue: 0.635),      // #A99AA2
        dark: Color(red: 0.580, green: 0.545, blue: 0.565)        // Visible but muted
    )
    
    // MARK: - Semantic Colors (Adaptive)
    
    static let successGreen = Color(
        light: Color(red: 0.545, green: 0.788, blue: 0.639),      // #8BC9A3
        dark: Color(red: 0.490, green: 0.835, blue: 0.600)        // Brighter green
    )
    
    static let warningYellow = Color(
        light: Color(red: 0.961, green: 0.847, blue: 0.604),      // #F5D89A
        dark: Color(red: 0.980, green: 0.867, blue: 0.545)        // Slightly brighter
    )
    
    static let errorRed = Color(
        light: Color(red: 0.910, green: 0.627, blue: 0.627),      // #E8A0A0
        dark: Color(red: 0.949, green: 0.569, blue: 0.569)        // Brighter for visibility
    )
    
    static let infoBlue = Color(
        light: Color(red: 0.659, green: 0.765, blue: 0.949),      // #A8C3F2
        dark: Color(red: 0.718, green: 0.808, blue: 0.969)        // Slightly brighter
    )
    
    // MARK: - Border Colors (Adaptive)
    
    static let borderColor = Color(
        light: Color(red: 0.941, green: 0.894, blue: 0.910),      // #F0E4E8
        dark: Color(red: 0.300, green: 0.280, blue: 0.290)        // Subtle dark border
    )
    
    static let dividerColor = Color(
        light: Color(red: 0.961, green: 0.933, blue: 0.941),      // #F5EEF0
        dark: Color(red: 0.250, green: 0.240, blue: 0.245)        // Subtle dark divider
    )
}

// MARK: - Adaptive Color Helper

extension Color {
    /// Creates an adaptive color that responds to light/dark mode
    init(light: Color, dark: Color) {
        self.init(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
}

// MARK: - Gradient Presets

extension LinearGradient {
    
    /// The signature gradient from the app icon - pink to blue diagonal
    static let lottaGradient = LinearGradient(
        colors: [.gradientPinkStart, .gradientBlueEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Horizontal pink gradient
    static let pinkGradient = LinearGradient(
        colors: [.gradientPinkStart, .gradientPinkEnd],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    /// Horizontal blue gradient
    static let blueGradient = LinearGradient(
        colors: [.gradientBlueStart, .gradientBlueEnd],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    /// Full icon gradient - top pink to bottom blue
    static let iconGradient = LinearGradient(
        colors: [.gradientPinkStart, .gradientPinkEnd, .gradientBlueEnd, .gradientBlueStart],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Usage Examples
/*
 
 All colors now automatically adapt to light/dark mode!
 
 // Button with primary color
 Button("Add to Collection") { }
     .buttonStyle(.borderedProminent)
     .tint(.primaryPink)
 
 // Card with subtle background
 RoundedRectangle(cornerRadius: 12)
     .fill(Color.backgroundSecondary)
 
 // Text hierarchy - automatically adapts
 VStack(alignment: .leading) {
     Text("Chocolate Rabbit Family")
         .foregroundColor(.textPrimary)      // Dark in light mode, light in dark mode
     Text("4 figures · Acquired 2024")
         .foregroundColor(.textSecondary)
 }
 
 */
