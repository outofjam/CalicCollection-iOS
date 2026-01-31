//
//  BirthdayMatchView.swift
//  CalicCollectionV2
//
//  Created by Ismail Dawoodjee on 2026-01-30.
//


//
//  BirthdayMatchView.swift
//  LottaPaws
//
//  Celebration modal when user adds a critter that shares their birthday
//

import SwiftUI
import Combine

struct BirthdayMatchView: View {
    let critterName: String
    let birthday: String
    let onDismiss: () -> Void
    
    @State private var showContent = false
    @State private var showConfetti = false
    
    private var formattedBirthday: String {
        AppSettings.formatBirthdayForDisplay(birthday) ?? birthday
    }
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissWithAnimation()
                }
            
            // Modal content
            VStack(spacing: LottaPawsTheme.spacingXL) {
                // Cake icon with animation
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.primaryPink.opacity(0.2), .secondaryBlue.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "birthday.cake.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primaryPink, .secondaryBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(showContent ? 1.0 : 0.5)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showContent)
                }
                
                // Title
                Text("Birthday Twin!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                
                // Message
                VStack(spacing: LottaPawsTheme.spacingSM) {
                    Text("You share a birthday with")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                    
                    Text(critterName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primaryPink)
                    
                    HStack(spacing: LottaPawsTheme.spacingXS) {
                        Image(systemName: "gift.fill")
                            .foregroundColor(.secondaryBlue)
                        Text(formattedBirthday)
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                }
                
                // Dismiss button
                Button {
                    dismissWithAnimation()
                } label: {
                    Text("Awesome! 🎉")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(LottaPawsTheme.spacingLG)
                        .background(
                            LinearGradient(
                                colors: [.primaryPink, .secondaryBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(LottaPawsTheme.radiusMD)
                }
            }
            .padding(LottaPawsTheme.spacingXL)
            .background(Color.backgroundPrimary)
            .cornerRadius(LottaPawsTheme.radiusXL)
            .shadow(
                color: LottaPawsTheme.shadowMedium.color,
                radius: LottaPawsTheme.shadowMedium.radius,
                x: 0,
                y: 8
            )
            .padding(LottaPawsTheme.spacingXL)
            .scaleEffect(showContent ? 1.0 : 0.8)
            .opacity(showContent ? 1.0 : 0.0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showContent = true
            }
            
            // Trigger extra confetti for birthday match
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                ConfettiManager.shared.trigger()
            }
        }
    }
    
    private func dismissWithAnimation() {
        withAnimation(.easeOut(duration: 0.2)) {
            showContent = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

// MARK: - Birthday Match Manager

@MainActor
class BirthdayMatchManager: ObservableObject {
    static let shared = BirthdayMatchManager()
    
    @Published var showMatch = false
    @Published var matchedCritterName: String = ""
    @Published var matchedBirthday: String = ""
    
    private init() {}
    
    /// Check for birthday match and show celebration if matched
    func checkAndCelebrate(critterName: String, critterBirthday: String?) {
        guard AppSettings.shared.isBirthdayMatch(critterBirthday),
              let birthday = critterBirthday else {
            return
        }
        
        matchedCritterName = critterName
        matchedBirthday = birthday
        showMatch = true
    }
    
    func dismiss() {
        showMatch = false
        matchedCritterName = ""
        matchedBirthday = ""
    }
}

// MARK: - View Modifier for Birthday Match

struct BirthdayMatchModifier: ViewModifier {
    @ObservedObject var manager = BirthdayMatchManager.shared
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if manager.showMatch {
                    BirthdayMatchView(
                        critterName: manager.matchedCritterName,
                        birthday: manager.matchedBirthday,
                        onDismiss: { manager.dismiss() }
                    )
                }
            }
    }
}

extension View {
    func birthdayMatch() -> some View {
        modifier(BirthdayMatchModifier())
    }
}

#Preview {
    ZStack {
        Color.backgroundPrimary.ignoresSafeArea()
        
        BirthdayMatchView(
            critterName: "Stella Hopscotch",
            birthday: "02-16",
            onDismiss: {}
        )
    }
}
