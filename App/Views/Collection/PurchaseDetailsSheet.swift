//
//  PurchaseDetailsSheet.swift
//  LottaPaws
//
//  Created by Ismail Dawoodjee on 2026-01-24.
//

import SwiftUI
import SwiftData

struct PurchaseDetailsSheet: View {
    let ownedVariant: OwnedVariant
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var pricePaid: String = ""
    @State private var purchaseDate: Date = Date()
    @State private var purchaseLocation: String = ""
    @State private var condition: String = "Mint"
    @State private var notes: String = ""
    
    private let conditions = ["Mint", "Like New", "Good", "Fair", "Poor"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Price Paid")
                            .foregroundColor(.textPrimary)
                        Spacer()
                        TextField("0.00", text: $pricePaid)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                        .tint(.primaryPink)
                    
                    TextField("Store or Location", text: $purchaseLocation)
                } header: {
                    Text("Purchase Information")
                }
                
                Section {
                    Picker("Condition", selection: $condition) {
                        ForEach(conditions, id: \.self) { condition in
                            Text(condition).tag(condition)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.primaryPink)
                } header: {
                    Text("Condition")
                }
                
                Section {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .foregroundColor(.textPrimary)
                } header: {
                    Text("Notes")
                } footer: {
                    Text("Any additional details about this figure")
                        .foregroundColor(.textTertiary)
                }
            }
            .navigationTitle("Purchase Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primaryPink)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePurchaseDetails()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryPink)
                }
            }
        }
        .tint(.primaryPink)
        .onAppear {
            loadExistingData()
        }
    }
    
    private func loadExistingData() {
        if let price = ownedVariant.pricePaid {
            pricePaid = String(format: "%.2f", price)
        }
        
        if let date = ownedVariant.purchaseDate {
            purchaseDate = date
        }
        
        if let location = ownedVariant.purchaseLocation {
            purchaseLocation = location
        }
        
        if let existingCondition = ownedVariant.condition {
            condition = existingCondition
        }
        
        if let existingNotes = ownedVariant.notes {
            notes = existingNotes
        }
    }
    
    private func savePurchaseDetails() {
        // Update owned variant
        ownedVariant.pricePaid = Double(pricePaid)
        ownedVariant.purchaseDate = purchaseDate
        ownedVariant.purchaseLocation = purchaseLocation.isEmpty ? nil : purchaseLocation
        ownedVariant.condition = condition
        ownedVariant.notes = notes.isEmpty ? nil : notes
        
        try? modelContext.save()
        
        ToastManager.shared.show("Purchase details saved", type: .success)
        
        dismiss()
    }
}

#Preview {
    Text("Preview")
}
