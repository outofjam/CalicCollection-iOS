//
//  PhotoDetailView.swift
//  LottaPaws
//

import SwiftUI
import SwiftData

struct PhotoDetailView: View {
    let photo: VariantPhoto
    let allPhotos: [VariantPhoto]
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var currentIndex: Int
    @State private var showingDeleteAlert = false
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    init(photo: VariantPhoto, allPhotos: [VariantPhoto]) {
        self.photo = photo
        self.allPhotos = allPhotos
        self._currentIndex = State(initialValue: allPhotos.firstIndex(where: { $0.id == photo.id }) ?? 0)
    }
    
    private var currentPhoto: VariantPhoto {
        allPhotos[currentIndex]
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Photo viewer with swipe navigation
            TabView(selection: $currentIndex) {
                ForEach(Array(allPhotos.enumerated()), id: \.element.id) { index, photo in
                    photoView(for: photo)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            
            // Top bar
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                    }
                    
                    Spacer()
                    
                    Text("\(currentIndex + 1) of \(allPhotos.count)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, LottaPawsTheme.spacingMD)
                        .padding(.vertical, LottaPawsTheme.spacingSM)
                        .background(.ultraThinMaterial)
                        .cornerRadius(LottaPawsTheme.radiusFull)
                    
                    Spacer()
                    
                    Menu {
                        Button {
                            sharePhoto()
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete Photo", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                    }
                }
                .padding(LottaPawsTheme.spacingLG)
                
                Spacer()
            }
        }
        .statusBar(hidden: true)
        .alert("Delete Photo?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteCurrentPhoto()
            }
        } message: {
            Text("This photo will be permanently deleted.")
        }
    }
    
    private func photoView(for photo: VariantPhoto) -> some View {
        Group {
            if let uiImage = UIImage(data: photo.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = lastScale * value
                            }
                            .onEnded { _ in
                                lastScale = scale
                                if scale < 1 {
                                    withAnimation(LottaPawsTheme.animationSpring) {
                                        scale = 1
                                        lastScale = 1
                                        offset = .zero
                                        lastOffset = .zero
                                    }
                                }
                            }
                    )
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                if scale > 1 {
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(LottaPawsTheme.animationSpring) {
                            if scale == 1 {
                                scale = 2
                                lastScale = 2
                            } else {
                                scale = 1
                                lastScale = 1
                                offset = .zero
                                lastOffset = .zero
                            }
                        }
                    }
            }
        }
    }
    
    // MARK: - Actions
    
    private func sharePhoto() {
        guard let uiImage = UIImage(data: currentPhoto.imageData) else {
            ToastManager.shared.show("Couldn't load photo", type: .error)
            return
        }
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              var topController = window.rootViewController else {
            AppLogger.error("Could not find root view controller")
            return
        }
        
        // Find the topmost presented controller
        while let presented = topController.presentedViewController {
            topController = presented
        }
        
        let activityVC = UIActivityViewController(
            activityItems: [uiImage],
            applicationActivities: nil
        )
        
        // For iPad
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = topController.view
            popover.sourceRect = CGRect(x: topController.view.bounds.midX, y: topController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        topController.present(activityVC, animated: true)
    }
    
    private func deleteCurrentPhoto() {
        modelContext.delete(currentPhoto)
        try? modelContext.save()
        
        ToastManager.shared.show("Photo deleted", type: .info)
        
        // If no more photos, dismiss
        if allPhotos.count == 1 {
            dismiss()
        } else if currentIndex >= allPhotos.count - 1 {
            currentIndex = max(0, currentIndex - 1)
        }
    }
}
