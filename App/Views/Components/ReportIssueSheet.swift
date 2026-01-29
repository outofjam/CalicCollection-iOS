//
//  ReportIssueSheet.swift
//  LottaPaws
//

import SwiftUI

struct ReportIssueSheet: View {
    let variantUuid: String
    let variantName: String
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedIssueType: ReportIssueType = .incorrectImage
    @State private var details: String = ""
    @State private var suggestedCorrection: String = ""
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(variantName)
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                } header: {
                    Text("Reporting Issue For")
                }
                
                Section {
                    Picker("Issue Type", selection: $selectedIssueType) {
                        ForEach(ReportIssueType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.primaryPink)
                } header: {
                    Text("What's Wrong?")
                }
                
                Section {
                    TextField("Describe the issue...", text: $details, axis: .vertical)
                        .lineLimit(3...6)
                        .foregroundColor(.textPrimary)
                } header: {
                    Text("Details (Optional)")
                }
                
                Section {
                    TextField("What should it be?", text: $suggestedCorrection)
                        .foregroundColor(.textPrimary)
                } header: {
                    Text("Suggested Correction (Optional)")
                }
            }
            .navigationTitle("Report Issue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primaryPink)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        Task {
                            await submitReport()
                        }
                    }
                    .disabled(isSubmitting)
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryPink)
                }
            }
            .disabled(isSubmitting)
            .overlay {
                if isSubmitting {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: LottaPawsTheme.spacingMD) {
                            ProgressView()
                                .tint(.primaryPink)
                            Text("Submitting...")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                        }
                        .padding(LottaPawsTheme.spacingXL)
                        .background(Color.backgroundPrimary)
                        .cornerRadius(LottaPawsTheme.radiusMD)
                        .shadow(
                            color: LottaPawsTheme.shadowMedium.color,
                            radius: LottaPawsTheme.shadowMedium.radius,
                            x: LottaPawsTheme.shadowMedium.x,
                            y: LottaPawsTheme.shadowMedium.y
                        )
                    }
                }
            }
        }
        .tint(.primaryPink)
        .toast()
    }
    
    private func submitReport() async {
        isSubmitting = true
        
        do {
            let message = try await APIService.shared.submitReport(
                variantUuid: variantUuid,
                issueType: selectedIssueType,
                details: details.isEmpty ? nil : details,
                suggestedCorrection: suggestedCorrection.isEmpty ? nil : suggestedCorrection
            )
            
            await MainActor.run {
                isSubmitting = false
                ToastManager.shared.show(message, type: .success)
                dismiss()
            }
            
        } catch {
            await MainActor.run {
                isSubmitting = false
                
                let userMessage: String
                if let apiError = error as? APIError {
                    switch apiError {
                    case .rateLimited:
                        userMessage = "You've submitted too many reports. Please try again later."
                    case .notFound:
                        userMessage = "Couldn't submit report. Please try again."
                    case .httpError(let code):
                        userMessage = "Server error (\(code)). Please try again later."
                    default:
                        userMessage = apiError.localizedDescription
                    }
                } else {
                    userMessage = "Couldn't submit report. Please check your connection."
                }
                
                ToastManager.shared.show(userMessage, type: .error)
            }
        }
    }
}

#Preview {
    ReportIssueSheet(variantUuid: "test-uuid", variantName: "Royal Princess Set")
}
