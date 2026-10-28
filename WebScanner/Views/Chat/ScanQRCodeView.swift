//
//  ScanQRCodeView.swift
//  WebScanner
//
//

import SwiftUI
import AVFoundation
import PhotosUI
import Vision

public struct ScanQRCodeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    private var navPath: Binding<NavigationPath>?
    
    @State private var isScanningActive: Bool = true
    @State private var scannedCodeToPresent: String? = nil
    @State private var isLaserMovingDown: Bool = false
    @State private var hasNavigated: Bool = false
    
    @State private var isPickerPresented: Bool = false
    @State private var selectedPickerItem: PhotosPickerItem? = nil
    @State private var isProcessingGalleryImage: Bool = false
    @State private var showNoQRCodeAlert: Bool = false
    
    @State private var cameraPermissionStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var showPermissionAlert: Bool = false
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    public init(navPath: Binding<NavigationPath>? = nil) {
        self.navPath = navPath
    }
    
    public var body: some View {
        GeometryReader { geo in
            let portraitWidth = min(geo.size.width, geo.size.height)
            let horizontalPadding: CGFloat = isIPad ? 32 : 20.scaled
            let viewfinderSize: CGFloat = isIPad ? 340 : min(portraitWidth - 72, 280.scaled)
            
            ZStack {
                cameraBackground(geo: geo)
                
                viewfinderOverlay(viewfinderSize: viewfinderSize, geo: geo)
                
                VStack(spacing: 0) {
                    headerBar(horizontalPadding: horizontalPadding)
                    
                    Spacer()
                    
                    galleryPickerButton(horizontalPadding: horizontalPadding, bottomInset: geo.safeAreaInsets.bottom)
                }
                
                if isProcessingGalleryImage {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        ProgressView()
                            .scaleEffect(1.3)
                            .tint(.white)
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .navigationBarHidden(true)
        .enableNativeSwipeBack()
        .onAppear {
            OrientationHelper.lockOrientation(.portrait)
            TabBarManager.shared.isHidden = true
            checkCameraPermission()
            hasNavigated = false
            isScanningActive = true
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                isLaserMovingDown = true
            }
        }
        .onDisappear {
            OrientationHelper.resetOrientation()
            isScanningActive = false
        }
        .photosPicker(
            isPresented: $isPickerPresented,
            selection: $selectedPickerItem,
            matching: .images
        )
        .onChange(of: isPickerPresented) { isPresented in
            if !isPresented && selectedPickerItem == nil && !hasNavigated {
                isScanningActive = true
            }
        }
        .onChange(of: selectedPickerItem) { newItem in
            handleGalleryItem(newItem)
        }
        .alert("No QR Code found in selected image".localized, isPresented: $showNoQRCodeAlert) {
            Button("OK".localized, role: .cancel) {
                if !hasNavigated {
                    isScanningActive = true
                }
            }
        }
        .alert("Camera Permission Required".localized, isPresented: $showPermissionAlert) {
            Button("Open Settings".localized) {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button("Cancel".localized, role: .cancel) {}
        } message: {
            Text("Please enable camera access in Settings to scan QR codes.".localized)
        }
        .navigationDestination(isPresented: Binding(
            get: { scannedCodeToPresent != nil && navPath == nil },
            set: { if !$0 { scannedCodeToPresent = nil; isScanningActive = true } }
        )) {
            if let code = scannedCodeToPresent {
                ScanDetailsView(scannedText: code, navPath: navPath)
            }
        }
    }
    
    // MARK: - Header Bar (< Scan QR Code)
    private func headerBar(horizontalPadding: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Button(action: {
                HapticFeedback.generate(.light)
                handleBack()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: isIPad ? 22 : 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: isIPad ? 44 : 36, height: isIPad ? 44 : 36)
                    .glassCard(cornerRadius: 12)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text("Scan QR Code".localized)
                .font(.inter(.bold, size: isIPad ? 20 : 20))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            Spacer()
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, isIPad ? 16 : 10)
        .padding(.bottom, isIPad ? 10 : 6)
    }
    
    // MARK: - Camera Background
    @ViewBuilder
    private func cameraBackground(geo: GeometryProxy) -> some View {
        #if targetEnvironment(simulator)
        ZStack {
            Color(hex: "#1A1D24").ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 48))
                    .foregroundColor(.white.opacity(0.3))
                Text("Camera Simulated in Simulator")
                    .font(.inter(.medium, size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        #else
        if cameraPermissionStatus == .authorized {
            QRCameraPreview(isActive: $isScanningActive) { code in
                handleDetectedCode(code)
            }
            .ignoresSafeArea()
        } else {
            ZStack {
                Color(hex: "#1A1D24").ignoresSafeArea()
                VStack(spacing: 14) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.white.opacity(0.5))
                    Text("Camera Access Needed".localized)
                        .font(.inter(.bold, size: 16))
                        .foregroundColor(.white)
                    Button("Open Settings".localized) {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.inter(.semiBold, size: 14))
                    .foregroundColor(Color(hex: "#16A34A"))
                }
                .padding(.horizontal, 32)
            }
        }
        #endif
    }
    
    // MARK: - Viewfinder Overlay with Animated Laser & Corner Brackets
    private func viewfinderOverlay(viewfinderSize: CGFloat, geo: GeometryProxy) -> some View {
        ZStack {
            ViewfinderMaskShape(cutoutSize: CGSize(width: viewfinderSize, height: viewfinderSize), cornerRadius: 24)
                .fill(Color.black.opacity(0.58), style: FillStyle(eoFill: true))
                .ignoresSafeArea()
            
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
                
                CornerBracketsShape(bracketLength: isIPad ? 46 : 38.scaled, cornerRadius: 20)
                    .stroke(
                        Color.black,
                        style: StrokeStyle(lineWidth: isIPad ? 5 : 4, lineCap: .round, lineJoin: .round)
                    )
                
                VStack {
                    if isLaserMovingDown {
                        Spacer()
                    }
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0),
                                    Color.black,
                                    Color.black.opacity(0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 3)
                        .padding(.horizontal, 16)
                        .shadow(color: Color.black.opacity(0.6), radius: 4, x: 0, y: 1)
                    
                    if !isLaserMovingDown {
                        Spacer()
                    }
                }
                .padding(.vertical, 16)
            }
            .frame(width: viewfinderSize, height: viewfinderSize)
        }
    }
    
    // MARK: - Gallery Picker Button (Choose From Gallery)
    private func galleryPickerButton(horizontalPadding: CGFloat, bottomInset: CGFloat) -> some View {
        Button(action: {
            HapticFeedback.generate(.light)
            TR_AdCountViewModel.sharedd.registerTap()
            isScanningActive = false
            isPickerPresented = true
        }) {
            Text("Choose From Gallery".localized)
                .font(.inter(.bold, size: isIPad ? 18 : 16.scaled))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: isIPad ? 56 : 50.scaled)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(hex: "#16A34A"))
                )
                .shadow(
                    color: Color(hex: "#16A34A").opacity(0.35),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, horizontalPadding)
        .padding(.bottom, max(bottomInset, 20) + 16)
    }
    
    // MARK: - Logic & Scanning Handlers
    private func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        cameraPermissionStatus = status
        
        if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.cameraPermissionStatus = granted ? .authorized : .denied
                    if !granted {
                        self.showPermissionAlert = true
                    }
                }
            }
        } else if status == .denied || status == .restricted {
            showPermissionAlert = true
        }
    }
    
    private func handleDetectedCode(_ code: String) {
        guard isScanningActive, !hasNavigated else { return }
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        isScanningActive = false
        hasNavigated = true
        HapticFeedback.generate(.success)
        
        navigateToDetails(code: trimmed)
    }
    
    private func handleGalleryItem(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        isScanningActive = false
        isProcessingGalleryImage = true
        
        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    detectCodeFromImage(uiImage) { detected in
                        DispatchQueue.main.async {
                            self.isProcessingGalleryImage = false
                            self.selectedPickerItem = nil
                            
                            if let code = detected, !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                guard !self.hasNavigated else { return }
                                self.hasNavigated = true
                                HapticFeedback.generate(.success)
                                self.navigateToDetails(code: code)
                            } else {
                                self.showNoQRCodeAlert = true
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isProcessingGalleryImage = false
                        self.selectedPickerItem = nil
                        self.showNoQRCodeAlert = true
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isProcessingGalleryImage = false
                    self.selectedPickerItem = nil
                    self.showNoQRCodeAlert = true
                }
            }
        }
    }
    
    private func detectCodeFromImage(_ image: UIImage, completion: @escaping (String?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        
        let request = VNDetectBarcodesRequest { req, error in
            if error == nil, let results = req.results as? [VNBarcodeObservation],
               let first = results.first(where: { $0.payloadStringValue != nil }),
               let payload = first.payloadStringValue {
                completion(payload)
                return
            }
            
            completion(detectWithCIDetector(image))
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                completion(detectWithCIDetector(image))
            }
        }
    }
    
    private func detectWithCIDetector(_ image: UIImage) -> String? {
        guard let ciImage = CIImage(image: image) else { return nil }
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        let features = detector?.features(in: ciImage) ?? []
        for feature in features {
            if let qr = feature as? CIQRCodeFeature, let message = qr.messageString {
                return message
            }
        }
        return nil
    }
    
    private func navigateToDetails(code: String) {
        if let nav = navPath {
            nav.wrappedValue.append(HomeDestination.scanDetails(code))
        } else {
            scannedCodeToPresent = code
        }
    }
    
    private func handleBack() {
        OrientationHelper.resetOrientation()
        if let nav = navPath, !nav.wrappedValue.isEmpty {
            nav.wrappedValue.removeLast()
        } else {
            dismiss()
        }
    }
}

// MARK: - Viewfinder Cutout Mask Shape
private struct ViewfinderMaskShape: Shape {
    let cutoutSize: CGSize
    let cornerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)
        
        let originX = rect.midX - (cutoutSize.width / 2)
        let originY = rect.midY - (cutoutSize.height / 2)
        let cutoutRect = CGRect(x: originX, y: originY, width: cutoutSize.width, height: cutoutSize.height)
        path.addPath(Path(roundedRect: cutoutRect, cornerRadius: cornerRadius))
        
        return path
    }
}

// MARK: - 4 Corner Brackets Shape
private struct CornerBracketsShape: Shape {
    let bracketLength: CGFloat
    let cornerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let r = cornerRadius
        let len = bracketLength
        
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + len))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        path.addQuadCurve(to: CGPoint(x: rect.minX + r, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + len, y: rect.minY))
        
        path.move(to: CGPoint(x: rect.maxX - len, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + r), control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + len))
        
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY - len))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - r))
        path.addQuadCurve(to: CGPoint(x: rect.minX + r, y: rect.maxY), control: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + len, y: rect.maxY))
        
        path.move(to: CGPoint(x: rect.maxX - len, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY - r), control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - len))
        
        return path
    }
}

// MARK: - Camera Live Preview Layer Controller
private struct QRCameraPreview: UIViewControllerRepresentable {
    @Binding var isActive: Bool
    let onCodeScanned: (String) -> Void
    
    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {
        if isActive {
            context.coordinator.reset()
            uiViewController.startScanning()
        } else {
            uiViewController.stopScanning()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, QRScannerDelegate {
        let parent: QRCameraPreview
        private var hasHandled: Bool = false
        
        init(parent: QRCameraPreview) {
            self.parent = parent
        }
        
        func reset() {
            hasHandled = false
        }
        
        func didFind(code: String) {
            guard !hasHandled else { return }
            hasHandled = true
            parent.onCodeScanned(code)
        }
    }
}

private protocol QRScannerDelegate: AnyObject {
    func didFind(code: String)
}

private class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: QRScannerDelegate?
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let sessionQueue = DispatchQueue(label: "com.webscanner.camera.sessionQueue")
    private var hasScanned: Bool = false
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        updatePreviewOrientation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updatePreviewOrientation()
        startScanning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopScanning()
    }
    
    private func updatePreviewOrientation() {
        guard let connection = previewLayer?.connection, connection.isVideoOrientationSupported else { return }
        connection.videoOrientation = .portrait
    }
    
    private func setupCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            let session = AVCaptureSession()
            session.beginConfiguration()
            
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
                  session.canAddInput(videoInput) else {
                session.commitConfiguration()
                return
            }
            
            session.addInput(videoInput)
            
            let metadataOutput = AVCaptureMetadataOutput()
            guard session.canAddOutput(metadataOutput) else {
                session.commitConfiguration()
                return
            }
            
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            
            // Support QR codes and all standard barcode formats
            let availableTypes = metadataOutput.availableMetadataObjectTypes
            let desiredTypes: [AVMetadataObject.ObjectType] = [
                .qr, .ean13, .ean8, .code128, .code39, .code93, .upce, .pdf417, .aztec, .dataMatrix
            ]
            let supportedTypes = desiredTypes.filter { availableTypes.contains($0) }
            metadataOutput.metadataObjectTypes = supportedTypes.isEmpty ? [.qr] : supportedTypes
            
            session.commitConfiguration()
            self.captureSession = session
            
            DispatchQueue.main.async {
                let preview = AVCaptureVideoPreviewLayer(session: session)
                preview.videoGravity = .resizeAspectFill
                preview.frame = self.view.bounds
                if let connection = preview.connection, connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
                self.view.layer.addSublayer(preview)
                self.previewLayer = preview
                
                self.sessionQueue.async {
                    session.startRunning()
                }
            }
        }
    }
    
    func startScanning() {
        hasScanned = false
        sessionQueue.async { [weak self] in
            guard let self = self, let session = self.captureSession, !session.isRunning else { return }
            session.startRunning()
        }
    }
    
    func stopScanning() {
        hasScanned = true
        sessionQueue.async { [weak self] in
            guard let self = self, let session = self.captureSession, session.isRunning else { return }
            session.stopRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !hasScanned else { return }
        guard let metadataObj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let stringValue = metadataObj.stringValue,
              !stringValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        hasScanned = true
        stopScanning()
        
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.didFind(code: stringValue)
        }
    }
}

#Preview {
    ScanQRCodeView()
}
