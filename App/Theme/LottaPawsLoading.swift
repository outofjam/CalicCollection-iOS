import SwiftUI

// MARK: - Loading Spinner

/// Styled loading indicator
struct LPLoadingSpinner: View {
    var size: CGFloat = 40
    var color: Color = .primaryPink
    
    var body: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: color))
            .scaleEffect(size / 40)
    }
}

/// Full-screen loading overlay
struct LPLoadingOverlay: View {
    var message: String? = nil
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: LottaPawsTheme.spacingLG) {
                LPLoadingSpinner(size: 50)
                
                if let message = message {
                    Text(message)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .padding(LottaPawsTheme.spacingXL)
            .background(
                RoundedRectangle(cornerRadius: LottaPawsTheme.radiusLG)
                    .fill(Color.textPrimary.opacity(0.9))
            )
        }
    }
}

/// Loading view for initial data fetch
struct LPLoadingView: View {
    var title: String = "Loading..."
    var subtitle: String? = nil
    
    var body: some View {
        VStack(spacing: LottaPawsTheme.spacingLG) {
            LPLoadingSpinner(size: 60)
            
            VStack(spacing: LottaPawsTheme.spacingSM) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundPrimary)
    }
}

// MARK: - Progress Bar

/// Linear progress bar
struct LPProgressBar: View {
    let progress: Double // 0.0 to 1.0
    var color: Color = .primaryPink
    var height: CGFloat = 8
    var showLabel: Bool = false
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Capsule()
                        .fill(Color.backgroundTertiary)
                    
                    // Progress
                    Capsule()
                        .fill(color)
                        .frame(width: geometry.size.width * min(max(progress, 0), 1))
                        .animation(.spring(response: 0.4), value: progress)
                }
            }
            .frame(height: height)
            
            if showLabel {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.textSecondary)
            }
        }
    }
}

/// Circular progress indicator
struct LPCircularProgress: View {
    let progress: Double // 0.0 to 1.0
    var size: CGFloat = 60
    var lineWidth: CGFloat = 6
    var color: Color = .primaryPink
    var showLabel: Bool = true
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.backgroundTertiary, lineWidth: lineWidth)
            
            // Progress arc
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.4), value: progress)
            
            // Label
            if showLabel {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: size * 0.28, weight: .bold))
                    .foregroundColor(.textPrimary)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Skeleton Loading

/// Skeleton placeholder for loading states
struct LPSkeleton: View {
    var width: CGFloat? = nil
    var height: CGFloat = 16
    var cornerRadius: CGFloat = LottaPawsTheme.radiusSM
    
    @State private var isAnimating = false
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.backgroundTertiary,
                        Color.backgroundSecondary,
                        Color.backgroundTertiary
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .cornerRadius(cornerRadius)
            .opacity(isAnimating ? 0.6 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

/// Skeleton for grid items
struct LPGridItemSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            LPSkeleton(height: 140, cornerRadius: 0)
            
            VStack(alignment: .leading, spacing: LottaPawsTheme.spacingSM) {
                LPSkeleton(width: 100, height: 14)
                LPSkeleton(width: 60, height: 12)
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
}

/// Skeleton for list items
struct LPListItemSkeleton: View {
    var body: some View {
        HStack(spacing: LottaPawsTheme.spacingMD) {
            LPSkeleton(width: 56, height: 56, cornerRadius: LottaPawsTheme.radiusSM)
            
            VStack(alignment: .leading, spacing: LottaPawsTheme.spacingSM) {
                LPSkeleton(width: 140, height: 14)
                LPSkeleton(width: 80, height: 12)
            }
            
            Spacer()
        }
        .padding(.vertical, LottaPawsTheme.spacingSM)
    }
}

// MARK: - Pull to Refresh

/// Styled refresh control appearance setup
/// Call this in your App init
func configureLottaPawsRefreshControl() {
    UIRefreshControl.appearance().tintColor = UIColor(Color.primaryPink)
}

// MARK: - Usage Examples
/*
 
 // Simple spinner
 LPLoadingSpinner()
 
 // Loading overlay
 ZStack {
     // Your content
     if isLoading {
         LPLoadingOverlay(message: "Syncing...")
     }
 }
 
 // Loading view (full screen)
 if isLoading {
     LPLoadingView(title: "Loading Collection", subtitle: "Please wait...")
 }
 
 // Progress bar
 LPProgressBar(progress: 0.65, showLabel: true)
 
 // Circular progress
 LPCircularProgress(progress: 0.75)
 LPCircularProgress(progress: 0.5, size: 80, color: .successGreen)
 
 // Skeleton loading
 if isLoading {
     LazyVGrid(columns: columns) {
         ForEach(0..<6, id: \.self) { _ in
             LPGridItemSkeleton()
         }
     }
 }
 
 // List skeleton
 if isLoading {
     ForEach(0..<5, id: \.self) { _ in
         LPListItemSkeleton()
     }
 }
 
 */
