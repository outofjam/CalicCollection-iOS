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
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                self.toast = Toast(message: message, type: type)
            }
            
            // Auto dismiss after 2 seconds
            dismissTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                
                guard !Task.isCancelled else { return }
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
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
        case .success: return .green
        case .error: return .red
        case .info: return .blue
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
                        .padding(.horizontal)
                        .padding(.top, 8)
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
        HStack(spacing: 12) {
            Image(systemName: toast.type.icon)
                .foregroundColor(toast.type.color)
                .font(.title3)
            
            Text(toast.message)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

/// View extension for easy toast
extension View {
    func toast() -> some View {
        modifier(ToastModifier())
    }
}
