//
//  FullscreenImageViewer.swift
//  LottaPaws
//
//  Unified fullscreen image viewer supporting both local files and remote URLs.
//  Features pinch-to-zoom and double-tap to zoom.
//

import SwiftUI

struct FullscreenImageViewer: View {
    let localImagePath: String?
    let remoteImageURL: String?
    
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Image content
            imageContent
                .scaleEffect(scale)
                .gesture(magnificationGesture)
                .onTapGesture(count: 2) { doubleTapZoom() }
            
            // Close button
            closeButton
        }
        .onTapGesture { dismiss() }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var imageContent: some View {
        if let localPath = localImagePath,
           let uiImage = UIImage(contentsOfFile: localPath) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else if let urlString = remoteImageURL,
                  let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure:
                    noImagePlaceholder
                default:
                    ProgressView()
                        .tint(.white)
                }
            }
        } else {
            noImagePlaceholder
        }
    }
    
    private var noImagePlaceholder: some View {
        VStack(spacing: LottaPawsTheme.spacingMD) {
            Image(systemName: "photo.slash")
                .font(.largeTitle)
                .foregroundColor(.textTertiary)
            Text("Image not available")
                .foregroundColor(.textTertiary)
        }
    }
    
    private var closeButton: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(LottaPawsTheme.spacingLG)
            }
            Spacer()
        }
    }
    
    // MARK: - Gestures
    
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = value
            }
            .onEnded { _ in
                withAnimation(LottaPawsTheme.animationSpring) {
                    scale = max(1.0, min(scale, 3.0))
                }
            }
    }
    
    private func doubleTapZoom() {
        withAnimation(LottaPawsTheme.animationSpring) {
            scale = scale > 1.0 ? 1.0 : 2.0
        }
    }
}

// MARK: - Convenience Initializers

extension FullscreenImageViewer {
    /// Initialize with just a remote URL (for browse/API variants)
    init(imageURL: String) {
        self.localImagePath = nil
        self.remoteImageURL = imageURL
    }
    
    /// Initialize with just a local path (for cached images)
    init(imagePath: String) {
        self.localImagePath = imagePath
        self.remoteImageURL = nil
    }
    
    /// Initialize from OwnedVariant (tries local first, then remote)
    init(ownedVariant: OwnedVariant) {
        self.localImagePath = ownedVariant.localImagePath
        self.remoteImageURL = ownedVariant.imageURL
    }
}

#Preview {
    FullscreenImageViewer(localImagePath: nil, remoteImageURL: nil)
}
