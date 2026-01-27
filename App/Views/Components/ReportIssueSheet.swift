import SwiftUI

struct ReportIssueSheet: View {
    let variant: CritterVariant
    let onSuccess: (String) -> Void // ADD THIS
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedIssueType: ReportIssueType = .incorrectImage
    @State private var details: String = ""
    @State private var suggestedCorrection: String = ""
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(variant.name)
                        .font(.headline)
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
                } header: {
                    Text("What's Wrong?")
                }
                
                Section {
                    TextField("Describe the issue...", text: $details, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Details (Optional)")
                }
                
                Section {
                    TextField("What should it be?", text: $suggestedCorrection)
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
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        Task {
                            await submitReport()
                        }
                    }
                    .disabled(isSubmitting)
                }
            }
            .disabled(isSubmitting)
            .overlay {
                if isSubmitting {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        ProgressView("Submitting...")
                            .padding()
                            .background(Color(uiColor: .systemBackground))
                            .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    private func submitReport() async {
        isSubmitting = true
        
        do {
            print("📤 Submitting report for variant: \(variant.uuid)")
            print("📤 Issue type: \(selectedIssueType.rawValue)")
            print("📤 Details: \(details)")
            
            let message = try await APIService.shared.submitReport(
                variantUuid: variant.uuid,
                issueType: selectedIssueType,
                details: details.isEmpty ? nil : details,
                suggestedCorrection: suggestedCorrection.isEmpty ? nil : suggestedCorrection
            )
            
            print("✅ Report submitted successfully: \(message)")
            
            isSubmitting = false
            // Dismiss FIRST
            dismiss()
            
            onSuccess(message)
            
            isSubmitting = false
            
        } catch {
            print("❌ Report submission failed: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            
            isSubmitting = false
            
            // Better error messages for users
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
