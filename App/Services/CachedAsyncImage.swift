//
//  CachedAsyncImage.swift
//  CalicCollectionV2
//
//  Created by Ismail Dawoodjee on 2026-01-26.
//


import SwiftUI

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: String
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    @State private var image: UIImage?
    @State private var isLoading = false
    
    init(
        url: String,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else {
                placeholder()
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        guard !isLoading else { return }
        isLoading = true
        
        image = await ImageCacheManager.shared.downloadAndCache(urlString: url)
        
        isLoading = false
    }
}

// Convenience init for URL instead of String
extension CachedAsyncImage {
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.init(
            url: url?.absoluteString ?? "",
            content: content,
            placeholder: placeholder
        )
    }
}