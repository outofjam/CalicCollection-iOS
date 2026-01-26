//
//  PhotoGallerySection.swift
//  CaliCollectionV2
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
    private let spacing: CGFloat = 12
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("My Photos", systemImage: "photo.on.rectangle.angled")
                    .font(.headline)
                
                Spacer()
                
                Text("\(photos.count)/12")
                    .font(.caption)
                    .foregroundColor(.calicoTextSecondary)
            }
            
            if photos.isEmpty {
                // Empty state
                Button {
                    showingPhotoPicker = true
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .foregroundColor(.calicoTextSecondary)
                        
                        Text("Add photos of your critter")
                            .font(.subheadline)
                            .foregroundColor(.calicoTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }
            } else {
                // Photo grid
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: spacing) {
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
                                        .foregroundColor(.calicoTextSecondary)
                                }
                                .frame(width: photoSize, height: photoSize)
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.calicoTextSecondary.opacity(0.3), lineWidth: 1)
                                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                                )
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
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
                    .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    }
            }
        }
    }
}
