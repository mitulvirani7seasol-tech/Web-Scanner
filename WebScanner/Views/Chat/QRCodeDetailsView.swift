//
//  QRCodeDetailsView.swift
//  WebScanner
//
//

import SwiftUI
import CoreImage

public struct QRCodeDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    public let resultText: String
    private var navPath: Binding<NavigationPath>?
    
    @State private var isCopied: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var qrCodeImage: UIImage? = nil
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    public init(resultText: String, navPath: Binding<NavigationPath>? = nil) {
        self.resultText = resultText
        self.navPath = navPath
    }
    
    public var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            let horizontalPadding: CGFloat = isIPad ? (isLandscape ? 48 : 32) : 18.scaled
            
            Image(colorScheme == .dark ? "BG_Dark" : "BG")
                .resizable()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1. Top Custom Navigation Header: < QR Code Details
                headerBar(horizontalPadding: horizontalPadding)
                
                // 2. Main Scrollable Content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: isIPad ? 20 : 16.scaled) {
                        // Card 1: QR Code Preview Card
                        qrPreviewCard
                        
                        // Card 2: Result text + Copy & Share buttons
                        resultCard
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, isIPad ? 14 : 10)
                    .padding(.bottom, max(geo.safeAreaInsets.bottom, 24) + 16)
                    .frame(maxWidth: isIPad ? .infinity : .infinity)
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .navigationBarHidden(true)
        .enableNativeSwipeBack()
        .onAppear {
            TabBarManager.shared.isHidden = true
            generateQRCodeImage()
        }
        .onDisappear {
            GenerateQRTabManager.shared.selectedTab = .qrCode
        }
        .sheet(isPresented: $showShareSheet) {
            if !resultText.isEmpty {
                ActivityView(activityItems: [resultText])
            }
        }
    }
    
    // MARK: - Header Bar (< QR Code Details)
    private func headerBar(horizontalPadding: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Button(action: {
                HapticFeedback.generate(.light)
                handleBack()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: isIPad ? 22 : 17, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    .frame(width: isIPad ? 44 : 36, height: isIPad ? 44 : 36)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text("QR Code Details".localized)
                .font(.inter(.bold, size: isIPad ? 20 : 20))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            Spacer()
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, isIPad ? 16 : 10)
        .padding(.bottom, isIPad ? 10 : 6)
    }
    
    // MARK: - Card 1: QR Code Preview
    private var qrPreviewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("QR Code Preview".localized)
                .font(.inter(.bold, size: isIPad ? 17 : 15.scaled))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            HStack {
                Spacer()
                if let qrImage = qrCodeImage {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: isIPad ? 300 : 220.scaled, height: isIPad ? 300 : 220.scaled)
                        .padding(.vertical, 8)
                } else {
                    ProgressView()
                        .frame(width: isIPad ? 300 : 220.scaled, height: isIPad ? 300 : 220.scaled)
                }
                Spacer()
            }
        }
        .padding(.horizontal, isIPad ? 20 : 16.scaled)
        .padding(.vertical, isIPad ? 18 : 14.scaled)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.35 : 0.85),
                            Color.white.opacity(colorScheme == .dark ? 0.08 : 0.25)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .glassModifier(cornerRadius: 18)
    }
    
    // MARK: - Card 2: Result text + Copy & Share buttons
    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Result".localized)
                .font(.inter(.bold, size: isIPad ? 17 : 15.scaled))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            // Inner Scanned Text Container
            Text(resultText)
                .font(.inter(.medium, size: isIPad ? 15 : 13.5.scaled))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                )
            
            // Action Buttons: Copy (outlined) & Share (filled green)
            HStack(spacing: 12) {
                // Copy Button (Outlined green)
                Button(action: {
                    TR_AdCountViewModel.sharedd.registerTap()
                    copyToClipboard()
                }) {
                    HStack(spacing: 6) {
                        if isCopied {
                            Image(systemName: "checkmark")
                                .font(.system(size: isIPad ? 16 : 14, weight: .bold))
                            Text("Copied!".localized)
                                .font(.inter(.bold, size: isIPad ? 16 : 14.scaled))
                        } else {
                            Text("Copy".localized)
                                .font(.inter(.bold, size: isIPad ? 16 : 14.scaled))
                        }
                    }
                    .foregroundColor(Color(hex: "#16A34A"))
                    .frame(maxWidth: .infinity)
                    .frame(height: isIPad ? 50 : 44.scaled)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color(hex: "#16A34A"), lineWidth: 1.5)
                    )
                }
                .contentShape(Rectangle())
                .glassModifier(cornerRadius: 24)
                
                // Share Button (Solid green)
                Button(action: {
                    HapticFeedback.generate(.light)
                    TR_AdCountViewModel.sharedd.registerTap()
                    showShareSheet = true
                }) {
                    Text("Share".localized)
                        .font(.inter(.bold, size: isIPad ? 16 : 14.scaled))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: isIPad ? 50 : 44.scaled)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color(hex: "#16A34A"))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, isIPad ? 20 : 16.scaled)
        .padding(.vertical, isIPad ? 18 : 14.scaled)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.35 : 0.85),
                            Color.white.opacity(colorScheme == .dark ? 0.08 : 0.25)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .glassModifier(cornerRadius: 18)
    }
    
    // MARK: - Actions
    private func copyToClipboard() {
        HapticFeedback.generate(.success)
        UIPasteboard.general.string = resultText
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isCopied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                isCopied = false
            }
        }
    }
    
    private func handleBack() {
        GenerateQRTabManager.shared.selectedTab = .qrCode
        if let nav = navPath {
            if nav.wrappedValue.count >= 2 {
                nav.wrappedValue.removeLast(2)
            } else if !nav.wrappedValue.isEmpty {
                nav.wrappedValue.removeLast()
            }
        } else {
            dismiss()
        }
    }
    
    private func generateQRCodeImage() {
        guard let data = resultText.data(using: .utf8) else { return }
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        
        guard let outputCI = filter.outputImage else { return }
        let scale: CGFloat = 10.0
        let transformed = outputCI.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        let context = CIContext()
        if let cgImg = context.createCGImage(transformed, from: transformed.extent) {
            qrCodeImage = UIImage(cgImage: cgImg)
        }
    }
}

#Preview {
    QRCodeDetailsView(resultText: "BEGIN:VCARD\nVERSION:3.0\nFN:Rahul Sharma\nTEL:9876543210\nADR:123 Green Park, Surat.\nEND:VCARD")
}
