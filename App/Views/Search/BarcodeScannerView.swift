import SwiftUI
import VisionKit

struct BarcodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var scannedBarcode: String?
    
    @State private var scannerIsActive = true
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var cameraReady = false
    
    var body: some View {
        ZStack {
            // Black background to prevent white flash
            Color.black.ignoresSafeArea()
            
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
                .opacity(cameraReady ? 1 : 0)
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
                        .foregroundColor(.calicoTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            // Loading indicator while camera initializes
            if !cameraReady && DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
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
        .onAppear {
            // Give camera time to initialize, then fade in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeIn(duration: 0.2)) {
                    cameraReady = true
                }
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
            qualityLevel: .fast,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
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
