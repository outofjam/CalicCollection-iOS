//
//  PhotoPickerSheet.swift
//  LottaPaws
//
//  Created by Ismail Dawoodjee on 2026-01-25.
//

import SwiftUI
import PhotosUI

struct PhotoPickerSheet: View {
    let variantUuid: String
    let onPhotosAdded: ([UIImage]) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showingCamera = false
    @State private var capturedImage: UIImage?
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        showingCamera = true
                    } label: {
                        Label("Take Photo", systemImage: "camera.fill")
                            .foregroundColor(.primaryPink)
                    }
                    
                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: 12,
                        matching: .images
                    ) {
                        Label("Choose from Library", systemImage: "photo.on.rectangle")
                            .foregroundColor(.primaryPink)
                    }
                } header: {
                    Text("Add Photos")
                } footer: {
                    Text("You can add up to 12 photos per variant")
                        .foregroundColor(.textTertiary)
                }
            }
            .navigationTitle("Add Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primaryPink)
                }
            }
            .onChange(of: selectedItems) { oldValue, newValue in
                Task {
                    await loadSelectedPhotos()
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView { image in
                    capturedImage = image
                    onPhotosAdded([image])
                    dismiss()
                }
            }
        }
        .tint(.primaryPink)
    }
    
    private func loadSelectedPhotos() async {
        var images: [UIImage] = []
        
        for item in selectedItems {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                images.append(image)
            }
        }
        
        if !images.isEmpty {
            onPhotosAdded(images)
            dismiss()
        }
    }
}

// MARK: - Camera View
struct CameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
