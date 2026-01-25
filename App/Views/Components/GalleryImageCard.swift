//
//  GalleryImageCard.swift
//  CalicCollectionV2
//
//  Created by Ismail Dawoodjee on 2026-01-25.
//


import SwiftUI

struct GalleryImageCard: View {
    let variant: OwnedVariant
    let cardHeight: CGFloat = 140

    @State private var isPressed = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Main image: user photo if exists, otherwise thumbnail/API image
            if let imageURL = userPhotoURL ?? variant.thumbnailURL ?? variant.imageURL,
               let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .empty:
                        placeholderImage
                    case .failure:
                        placeholderImage
                    @unknown default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }

            // Gradient overlay for text readability
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Variant info
            VStack(alignment: .leading, spacing: 2) {
                Text(variant.variantName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(variant.critterName)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
            }
            .padding(6)
            
            // Optional badges
            HStack {
                if variant.quantity > 1 {
                    badge(text: "\(variant.quantity)x")
                }
                if let condition = variant.condition, !condition.isEmpty {
                    badge(text: condition.prefix(3).uppercased())
                }
                Spacer()
            }
            .padding(6)
            .padding(.top, 4)
            .frame(maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: 0.05, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }

    // MARK: - User photo placeholder
    private var userPhotoURL: String? {
        variant.userPhotos?.first
    }

    private var placeholderImage: some View {
        Color.gray.opacity(0.2)
            .overlay {
                Image(systemName: "photo")
                    .foregroundColor(.gray)
            }
    }

    // MARK: - Badge
    private func badge(text: String) -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Color.blue.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
