import SwiftUI
import AVFoundation

public struct QRCodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    public let title: String
    public let subtitle: String
    public let onScan: (String) -> Void

    @State private var torchOn: Bool = false
    @State private var isSimulated: Bool = false
    @State private var manualInput: String = ""
    @State private var showManualAlert: Bool = false
    @State private var scanLineOffset: CGFloat = -110

    public init(
        title: String = "Scan Barcode / QR Code",
        subtitle: String = "Align product QR code, tag barcode, or serial number within frame",
        onScan: @escaping (String) -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.onScan = onScan
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                // Camera Feed or Simulator View
                CameraPreviewRepresentable(
                    torchOn: torchOn,
                    onScan: { code in
                        handleScanned(code: code)
                    },
                    onCameraUnavailable: {
                        isSimulated = true
                    }
                )
                .ignoresSafeArea()

                // Scanning HUD Overlay
                VStack(spacing: 0) {
                    // Top Info Banner
                    VStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)

                        Text(subtitle)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(.white.opacity(0.75))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [Color.black.opacity(0.85), Color.black.opacity(0.3), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    Spacer()

                    // Viewfinder Target Reticle
                    ZStack {
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            .frame(width: 260, height: 260)

                        // 4 Golden Corner Reticles
                        ScannerCorners()
                            .stroke(Color(red: 0.95, green: 0.75, blue: 0.40), lineWidth: 4)
                            .frame(width: 260, height: 260)

                        // Animated Scanning Laser
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.95, green: 0.75, blue: 0.40).opacity(0),
                                        Color(red: 0.95, green: 0.75, blue: 0.40).opacity(0.85),
                                        Color(red: 0.95, green: 0.75, blue: 0.40).opacity(0)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 240, height: 3)
                            .offset(y: scanLineOffset)
                            .onAppear {
                                withAnimation(
                                    .easeInOut(duration: 1.8)
                                    .repeatForever(autoreverses: true)
                                ) {
                                    scanLineOffset = 110
                                }
                            }

                        if isSimulated {
                            VStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(.white.opacity(0.6))
                                Text("Camera Preview")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.7))
                                Text("(Tap 'Enter Manually' to test on simulator)")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }
                    }

                    Spacer()

                    // Bottom Action Controls
                    HStack(spacing: 36) {
                        // Torch Toggle Button
                        Button {
                            torchOn.toggle()
                        } label: {
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .fill(torchOn ? Color.yellow : Color.white.opacity(0.2))
                                        .frame(width: 50, height: 50)
                                    Image(systemName: torchOn ? "bolt.fill" : "bolt.slash.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(torchOn ? .black : .white)
                                }
                                Text("Torch")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }

                        // Manual Entry Button
                        Button {
                            showManualAlert = true
                        } label: {
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 50, height: 50)
                                    Image(systemName: "keyboard")
                                        .font(.system(size: 20))
                                        .foregroundStyle(.white)
                                }
                                Text("Enter Code")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                    }
                    .padding(.bottom, 36)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.6), Color.black.opacity(0.9)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
            .alert("Enter Barcode / Product URL", isPresented: $showManualAlert) {
                TextField("e.g. 8901030784918 or URL", text: $manualInput)
                Button("Done") {
                    let trimmed = manualInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        handleScanned(code: trimmed)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Type or paste any product barcode, QR link, or SKU number.")
            }
        }
    }

    private func handleScanned(code: String) {
        AudioServicesPlaySystemSound(SystemSoundID(1108)) // Camera shutter / beep
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
        dismiss()
        onScan(code)
    }
}

// MARK: - Reticle Corner Shape
struct ScannerCorners: Shape {
    let cornerLength: CGFloat = 28

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Top-Left
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + cornerLength))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + 16))
        path.addQuadCurve(to: CGPoint(x: rect.minX + 16, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + cornerLength, y: rect.minY))

        // Top-Right
        path.move(to: CGPoint(x: rect.maxX - cornerLength, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - 16, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + 16), control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cornerLength))

        // Bottom-Right
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerLength))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 16))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - 16, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - cornerLength, y: rect.maxY))

        // Bottom-Left
        path.move(to: CGPoint(x: rect.minX + cornerLength, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + 16, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - 16), control: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cornerLength))

        return path
    }
}

// MARK: - AVCapture Video Representable
struct CameraPreviewRepresentable: UIViewControllerRepresentable {
    let torchOn: Bool
    let onScan: (String) -> Void
    let onCameraUnavailable: () -> Void

    func makeUIViewController(context: Context) -> CameraScannerViewController {
        let controller = CameraScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraScannerViewController, context: Context) {
        uiViewController.setTorch(on: torchOn)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan, onCameraUnavailable: onCameraUnavailable)
    }

    class Coordinator: NSObject, CameraScannerDelegate {
        let onScan: (String) -> Void
        let onCameraUnavailable: () -> Void

        init(onScan: @escaping (String) -> Void, onCameraUnavailable: @escaping () -> Void) {
            self.onScan = onScan
            self.onCameraUnavailable = onCameraUnavailable
        }

        func didFindCode(_ code: String) {
            onScan(code)
        }

        func cameraUnavailable() {
            onCameraUnavailable()
        }
    }
}

protocol CameraScannerDelegate: AnyObject {
    func didFindCode(_ code: String)
    func cameraUnavailable()
}

class CameraScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: CameraScannerDelegate?

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var isScanned = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isScanned = false
        if let session = captureSession, !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let session = captureSession, session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                session.stopRunning()
            }
        }
    }

    private func setupCamera() {
        let session = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            delegate?.cameraUnavailable()
            return
        }

        guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              session.canAddInput(videoInput) else {
            delegate?.cameraUnavailable()
            return
        }

        session.addInput(videoInput)

        let metadataOutput = AVCaptureMetadataOutput()
        guard session.canAddOutput(metadataOutput) else {
            delegate?.cameraUnavailable()
            return
        }

        session.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)

        // Comprehensive barcode & QR code types
        let supportedTypes: [AVMetadataObject.ObjectType] = [
            .qr,
            .ean13,
            .ean8,
            .upce,
            .code128,
            .code39,
            .code93,
            .dataMatrix,
            .aztec,
            .pdf417,
            .itf14
        ]
        
        let availableTypes = metadataOutput.availableMetadataObjectTypes
        metadataOutput.metadataObjectTypes = supportedTypes.filter { availableTypes.contains($0) }

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.frame = view.layer.bounds
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)

        self.previewLayer = preview
        self.captureSession = session

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    func setTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("Failed to set torch: \(error)")
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !isScanned,
              let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let stringValue = metadataObject.stringValue,
              !stringValue.isEmpty else {
            return
        }

        isScanned = true
        captureSession?.stopRunning()
        delegate?.didFindCode(stringValue)
    }
}
