//
//  FilterChipsView.swift
//  CalicCollectionV2
//
//  Created by Ismail Dawoodjee on 2026-01-28.
//


import SwiftUI

// MARK: - Filter Chips View
struct FilterChipsView: View {
    @Binding var selectedFamilyUuid: String?
    @Binding var selectedFamilyName: String?
    let families: [Family]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Family filter
                Menu {
                    Button("All Families") {
                        selectedFamilyUuid = nil
                        selectedFamilyName = nil
                    }
                    
                    Divider()
                    
                    ForEach(families.sorted(by: { $0.name < $1.name })) { family in
                        Button {
                            selectedFamilyUuid = family.uuid
                            selectedFamilyName = family.name
                        } label: {
                            HStack {
                                Text(family.name)
                                Spacer()
                                Text("\(family.crittersCount)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.caption)
                        Text(selectedFamilyName ?? "All Families")
                            .font(.subheadline)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(selectedFamilyUuid != nil ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(selectedFamilyUuid != nil ? .white : .primary)
                    .clipShape(Capsule())
                }
                
                // Clear filter
                if selectedFamilyUuid != nil {
                    Button {
                        selectedFamilyUuid = nil
                        selectedFamilyName = nil
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                            Text("Clear")
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.calicoError)
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }
}