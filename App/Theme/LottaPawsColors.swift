import SwiftUI

// MARK: - LottaPaws Color Palette
// Generated from app icon - kawaii pastel gradient aesthetic

extension Color {
    
    // MARK: - Gradient Colors
    // Use these for header backgrounds, hero sections
    
    static let gradientPinkStart = Color(red: 0.941, green: 0.718, blue: 0.843)  // #F0B7D7
    static let gradientPinkEnd = Color(red: 0.957, green: 0.784, blue: 0.875)    // #F4C8DF
    static let gradientBlueStart = Color(red: 0.639, green: 0.757, blue: 0.953)  // #A3C1F3
    static let gradientBlueEnd = Color(red: 0.765, green: 0.741, blue: 0.914)    // #C3BDE9
    
    // MARK: - Primary Colors
    // Main actions, buttons, key UI elements
    
    static let primaryPink = Color(red: 0.910, green: 0.643, blue: 0.788)        // #E8A4C9
    static let primaryPinkLight = Color(red: 0.957, green: 0.820, blue: 0.898)   // #F4D1E5
    static let primaryPinkDark = Color(red: 0.788, green: 0.482, blue: 0.639)    // #C97BA3
    
    // MARK: - Secondary Colors
    // Secondary actions, less prominent elements
    
    static let secondaryBlue = Color(red: 0.659, green: 0.765, blue: 0.949)      // #A8C3F2
    static let secondaryBlueLight = Color(red: 0.784, green: 0.851, blue: 0.973) // #C8D9F8
    static let secondaryBlueDark = Color(red: 0.478, green: 0.608, blue: 0.831)  // #7A9BD4
    
    // MARK: - Accent Colors
    // Highlights, badges, special callouts
    
    static let accentBlush = Color(red: 0.949, green: 0.808, blue: 0.855)        // #F2CEDA
    static let accentWarm = Color(red: 1.000, green: 0.706, blue: 0.706)         // #FFB4B4
    
    // MARK: - Background Colors
    
    static let backgroundPrimary = Color.white                                    // #FFFFFF
    static let backgroundSecondary = Color(red: 1.000, green: 0.973, blue: 0.980) // #FFF8FA
    static let backgroundTertiary = Color(red: 0.973, green: 0.957, blue: 0.976)  // #F8F4F9
    
    // MARK: - Text Colors
    
    static let textPrimary = Color(red: 0.290, green: 0.227, blue: 0.259)         // #4A3A42
    static let textSecondary = Color(red: 0.478, green: 0.416, blue: 0.447)       // #7A6A72
    static let textTertiary = Color(red: 0.663, green: 0.604, blue: 0.635)        // #A99AA2
    
    // MARK: - Semantic Colors
    
    static let successGreen = Color(red: 0.545, green: 0.788, blue: 0.639)        // #8BC9A3
    static let warningYellow = Color(red: 0.961, green: 0.847, blue: 0.604)       // #F5D89A
    static let errorRed = Color(red: 0.910, green: 0.627, blue: 0.627)            // #E8A0A0
    static let infoBlue = Color(red: 0.659, green: 0.765, blue: 0.949)            // #A8C3F2
    
    // MARK: - Border Colors
    
    static let borderColor = Color(red: 0.941, green: 0.894, blue: 0.910)         // #F0E4E8
    static let dividerColor = Color(red: 0.961, green: 0.933, blue: 0.941)        // #F5EEF0
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
 
 // Button with primary color
 Button("Add to Collection") { }
     .buttonStyle(.borderedProminent)
     .tint(.primaryPink)
 
 // Card with subtle background
 RoundedRectangle(cornerRadius: 12)
     .fill(Color.backgroundSecondary)
 
 // Header with gradient
 VStack {
     Text("My Collection")
         .foregroundColor(.textPrimary)
 }
 .frame(maxWidth: .infinity)
 .background(LinearGradient.lottaGradient)
 
 // Text hierarchy
 VStack(alignment: .leading) {
     Text("Chocolate Rabbit Family")
         .foregroundColor(.textPrimary)
     Text("4 figures · Acquired 2024")
         .foregroundColor(.textSecondary)
 }
 
 // Border/divider
 Divider()
     .background(Color.dividerColor)
 
 */
