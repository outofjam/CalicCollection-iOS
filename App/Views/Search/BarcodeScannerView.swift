import SwiftUI
import VisionKit

struct BarcodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var scannedBarcode: String?
    
    @State private var scannerIsActive = true
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            // Camera scanner
            if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                DataScannerRepresentable(
                    recognizedDataTypes: [.barcode()],
                    isScanning: $scannerIsActive,
                    scannedBarcode: $scannedBarcode,
                    onError: { error in
                        errorMessage = error
                        showError = true
                    }
                )
                .ignoresSafeArea()
            } else {
                // Fallback for unsupported devices
                VStack(spacing: 20) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("Scanner Not Available")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("This device doesn't support barcode scanning")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            // Overlay UI
            VStack {
                // Top bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                    }
                    .padding()
                    
                    Spacer()
                }
                
                Spacer()
                
                // Instructions
                VStack(spacing: 12) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                    
                    Text("Scan Set Barcode")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Point camera at the barcode on your Calico Critters set box")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 60)
            }
        }
        .alert("Scanner Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

// MARK: - DataScanner Representable
struct DataScannerRepresentable: UIViewControllerRepresentable {
    let recognizedDataTypes: Set<DataScannerViewController.RecognizedDataType>
    @Binding var isScanning: Bool
    @Binding var scannedBarcode: String?
    let onError: (String) -> Void
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: recognizedDataTypes,
            qualityLevel: .fast,  // Changed from .balanced to .fast
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,  // Disabled for better performance
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        
        scanner.delegate = context.coordinator
        
        // Start scanning immediately
        try? scanner.startScanning()
        
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        if isScanning {
            try? uiViewController.startScanning()
        } else {
            uiViewController.stopScanning()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(scannedBarcode: $scannedBarcode, onError: onError)
    }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        @Binding var scannedBarcode: String?
        let onError: (String) -> Void
        
        init(scannedBarcode: Binding<String?>, onError: @escaping (String) -> Void) {
            self._scannedBarcode = scannedBarcode
            self.onError = onError
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            handleScannedItem(item)
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            // Auto-scan first recognized barcode
            if let item = addedItems.first {
                handleScannedItem(item)
            }
        }
        
        private func handleScannedItem(_ item: RecognizedItem) {
            switch item {
            case .barcode(let barcode):
                if let barcodeString = barcode.payloadStringValue {
                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    
                    // Set scanned barcode (triggers parent view)
                    scannedBarcode = barcodeString
                }
            default:
                break
            }
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didFailWithError error: Error) {
            onError(error.localizedDescription)
        }
    }
}

#Preview {
    BarcodeScannerView(scannedBarcode: .constant(nil))
}
