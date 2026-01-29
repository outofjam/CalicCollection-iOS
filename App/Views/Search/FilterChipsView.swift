//
//  FilterChipsView.swift
//  LottaPaws
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
            HStack(spacing: LottaPawsTheme.spacingSM) {
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
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: LottaPawsTheme.spacingXS) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.caption)
                        Text(selectedFamilyName ?? "All Families")
                            .font(.subheadline)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .padding(.horizontal, LottaPawsTheme.spacingMD)
                    .padding(.vertical, LottaPawsTheme.spacingSM)
                    .background(selectedFamilyUuid != nil ? Color.primaryPink : Color.backgroundSecondary)
                    .foregroundColor(selectedFamilyUuid != nil ? .white : .textPrimary)
                    .clipShape(Capsule())
                    .overlay(
                        selectedFamilyUuid == nil ?
                        Capsule().stroke(Color.borderColor, lineWidth: 1) :
                        nil
                    )
                }
                
                // Clear filter
                if selectedFamilyUuid != nil {
                    Button {
                        selectedFamilyUuid = nil
                        selectedFamilyName = nil
                    } label: {
                        HStack(spacing: LottaPawsTheme.spacingXS) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                            Text("Clear")
                                .font(.subheadline)
                        }
                        .padding(.horizontal, LottaPawsTheme.spacingMD)
                        .padding(.vertical, LottaPawsTheme.spacingSM)
                        .background(Color.errorRed.opacity(0.12))
                        .foregroundColor(.errorRed)
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, LottaPawsTheme.spacingLG)
            .padding(.vertical, LottaPawsTheme.spacingSM)
        }
        .background(Color.backgroundSecondary)
    }
}
