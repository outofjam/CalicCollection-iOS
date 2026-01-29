//
//  ToastManager.swift
//  LottaPaws
//

import SwiftUI
import Combine

/// Toast notification manager
@MainActor
class ToastManager: ObservableObject {
    static let shared = ToastManager()
    
    @Published var toast: Toast?
    private var dismissTask: Task<Void, Never>?
    
    private init() {}
    
    func show(_ message: String, type: ToastType = .success) {
        // Cancel any existing dismiss task
        dismissTask?.cancel()
        
        // Dismiss existing toast
        toast = nil
        
        // Show new toast after brief delay
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(100))
            
            withAnimation(LottaPawsTheme.animationSpring) {
                self.toast = Toast(message: message, type: type)
            }
            
            // Auto dismiss after 2 seconds
            dismissTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                
                guard !Task.isCancelled else { return }
                
                withAnimation(LottaPawsTheme.animationSpring) {
                    self.toast = nil
                }
            }
        }
    }
}

/// Toast model
struct Toast: Equatable {
    let id = UUID()
    let message: String
    let type: ToastType
}

/// Toast types
enum ToastType {
    case success
    case error
    case info
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success: return .successGreen
        case .error: return .errorRed
        case .info: return .infoBlue
        }
    }
}

/// Toast view modifier
struct ToastModifier: ViewModifier {
    @ObservedObject var toastManager = ToastManager.shared
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if let toast = toastManager.toast {
                VStack {
                    ToastView(toast: toast)
                        .padding(.horizontal, LottaPawsTheme.spacingLG)
                        .padding(.top, LottaPawsTheme.spacingSM)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    
                    Spacer()
                }
                .zIndex(999)
            }
        }
    }
}

/// Toast view
struct ToastView: View {
    let toast: Toast
    
    var body: some View {
        HStack(spacing: LottaPawsTheme.spacingMD) {
            Image(systemName: toast.type.icon)
                .foregroundColor(toast.type.color)
                .font(.title3)
            
            Text(toast.message)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.textPrimary)
            
            Spacer()
        }
        .padding(LottaPawsTheme.spacingMD)
        .background(
            RoundedRectangle(cornerRadius: LottaPawsTheme.radiusMD)
                .fill(Color.backgroundPrimary)
                .shadow(
                    color: LottaPawsTheme.shadowMedium.color,
                    radius: LottaPawsTheme.shadowMedium.radius,
                    x: LottaPawsTheme.shadowMedium.x,
                    y: LottaPawsTheme.shadowMedium.y
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: LottaPawsTheme.radiusMD)
                .stroke(toast.type.color.opacity(0.3), lineWidth: 1)
        )
    }
}

/// View extension for easy toast
extension View {
    func toast() -> some View {
        modifier(ToastModifier())
    }
}
