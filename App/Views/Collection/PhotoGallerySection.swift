//
//  PhotoGallerySection.swift
//  LottaPaws
//
//  Created by Ismail Dawoodjee on 2026-01-25.
//

import SwiftUI
import SwiftData

struct PhotoGallerySection: View {
    let variantUuid: String
    
    @Environment(\.modelContext) private var modelContext
    @Query private var allPhotos: [VariantPhoto]
    
    @State private var showingPhotoPicker = false
    @State private var selectedPhoto: VariantPhoto?
    
    private var photos: [VariantPhoto] {
        allPhotos
            .filter { $0.variantUuid == variantUuid }
            .sorted { $0.sortOrder < $1.sortOrder }
    }
    
    private let photoSize: CGFloat = 80
    
    var body: some View {
        VStack(alignment: .leading, spacing: LottaPawsTheme.spacingMD) {
            HStack {
                Label("My Photos", systemImage: "photo.on.rectangle.angled")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Text("\(photos.count)/12")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }
            
            if photos.isEmpty {
                // Empty state
                Button {
                    showingPhotoPicker = true
                } label: {
                    VStack(spacing: LottaPawsTheme.spacingSM) {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .foregroundColor(.textTertiary)
                        
                        Text("Add photos of your critter")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(Color.backgroundSecondary)
                    .cornerRadius(LottaPawsTheme.radiusMD)
                    .overlay(
                        RoundedRectangle(cornerRadius: LottaPawsTheme.radiusMD)
                            .stroke(Color.borderColor, lineWidth: 1)
                    )
                }
            } else {
                // Photo grid
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: LottaPawsTheme.spacingMD) {
                        ForEach(photos) { photo in
                            PhotoThumbnail(photo: photo)
                                .onTapGesture {
                                    selectedPhoto = photo
                                }
                        }
                        
                        // Add button
                        if photos.count < 12 {
                            Button {
                                showingPhotoPicker = true
                            } label: {
                                VStack {
                                    Image(systemName: "plus")
                                        .font(.title2)
                                        .foregroundColor(.primaryPink)
                                }
                                .frame(width: photoSize, height: photoSize)
                                .background(Color.backgroundSecondary)
                                .cornerRadius(LottaPawsTheme.radiusSM)
                                .overlay(
                                    RoundedRectangle(cornerRadius: LottaPawsTheme.radiusSM)
                                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                                        .foregroundColor(.primaryPink.opacity(0.5))
                                )
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, LottaPawsTheme.spacingSM)
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPickerSheet(variantUuid: variantUuid) { images in
                savePhotos(images)
            }
        }
        .fullScreenCover(item: $selectedPhoto) { photo in
            PhotoDetailView(photo: photo, allPhotos: photos)
        }
    }
    
    private func savePhotos(_ images: [UIImage]) {
        let currentCount = photos.count
        let remainingSlots = 12 - currentCount
        let imagesToSave = Array(images.prefix(remainingSlots))
        
        for (index, image) in imagesToSave.enumerated() {
            // Compress image
            guard let imageData = image.jpegData(compressionQuality: 0.8) else { continue }
            
            let photo = VariantPhoto(
                variantUuid: variantUuid,
                imageData: imageData,
                sortOrder: currentCount + index
            )
            
            modelContext.insert(photo)
        }
        
        try? modelContext.save()
        
        let count = imagesToSave.count
        ToastManager.shared.show("Added \(count) photo\(count == 1 ? "" : "s")", type: .success)
    }
}

// MARK: - Photo Thumbnail
struct PhotoThumbnail: View {
    let photo: VariantPhoto
    
    var body: some View {
        Group {
            if let uiImage = UIImage(data: photo.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipped()
                    .cornerRadius(LottaPawsTheme.radiusSM)
            } else {
                Rectangle()
                    .fill(Color.backgroundTertiary)
                    .frame(width: 80, height: 80)
                    .cornerRadius(LottaPawsTheme.radiusSM)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundColor(.textTertiary)
                    }
            }
        }
    }
}
