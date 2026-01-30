//
//  InfoRow.swift
//  LottaPaws
//
//  Created by Ismail Dawoodjee on 2026-01-27.
//

import SwiftUI

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(.textPrimary)
        }
    }
}
